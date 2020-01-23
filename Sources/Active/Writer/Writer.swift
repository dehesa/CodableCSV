import Foundation

/// Sequentially writes string values and/or array of strings into a CSV file format.
public final class CSVWriter {
    /// Generic configuration variables for the writer.
    public let configuration: EncoderConfiguration
    
    /// Specific configuration variables for these CSV writing passes.
    private var settings: Settings
    /// Encoder used to transform unicode scalars into a bunch of bytes.
    private let encoder: Unicode.Scalar.Encoder
    /// Unicode scalar buffer to keep scalars that hasn't yet been analysed.
    private let buffer: Buffer
    /// Check whether the given unicode scalar is part of the field delimiter sequence.
    private let isFieldDelimiter: DelimiterChecker
    /// Check whether the given unicode scalar is par of the row delimiter sequence.
    private let isRowDelimiter: DelimiterChecker
    /// The output stream holding the writing data blob.
    private let output: (stream: OutputStream, closeAtEnd: Bool)
    
    /// The number of fields per row that are expected.
    private(set) internal var expectedFieldsPerRow: Int?
    /// The writer state indicating whether it has already begun working or it is idle.
    private var state: (file: State.File, row: State.Row)
    
    /// Designated initializer that will set up the CSV writer.
    ///
    /// To start "writing", call `beginFile()` after this initializer.
    /// ```swift
    /// let writer = try CSVWriter(output: (stream, true), configuration: config, encoder: transformer)
    /// try writer.beginFile()
    ///
    /// try writer.beginRow()
    /// try writer.write(field: "Coco")
    /// try writer.write(field: "Dog")
    /// try writer.write(field: "2")
    /// try writer.endRow()
    ///
    /// try writer.endFile()
    /// ```
    /// - parameter output: The output stream on where to write the encoded rows/fields.
    /// - parameter configuration: The configurations for the writer.
    /// - parameter encoder: The function transforming unicode scalars into the desired binary representation.
    /// - throws: `CSVWriter.Error` exclusively.
    internal init(output: (stream: OutputStream, closeAtEnd: Bool), configuration: EncoderConfiguration, encoder: @escaping Unicode.Scalar.Encoder) throws {
        self.configuration = configuration
        self.settings = try Settings(configuration: configuration)
        
        self.buffer = Buffer(reservingCapacity: max(self.settings.delimiters.field.count, self.settings.delimiters.row.count) + 1)
        self.encoder = encoder
        self.isFieldDelimiter = CSVWriter.matchCreator(delimiter: self.settings.delimiters.field, buffer: self.buffer)
        self.isRowDelimiter = CSVWriter.matchCreator(delimiter: self.settings.delimiters.row, buffer: self.buffer)
        
        self.output = (output.stream, output.closeAtEnd)
        self.expectedFieldsPerRow = nil
        self.state = (.initialized, .unstarted)
    }
    
    deinit {
        try? self.endFile()
    }
    
    /// The encoding position; a.k.a. the row and field index to write next.
    ///
    /// Every time a row is fully writen, the row index gets bumped by 1.
    /// - warning: If the CSV has indicated a header row in its configuration, it won't be indicated here.
    public var indices: (row: Int, field: Int) {
        switch state.file {
        case .initialized:           return (0, 0)
        case .started(let rowIndex): return (rowIndex, self.state.row.nextIndex)
        case .closed(let rowIndex):  return (rowIndex, 0)
        }
    }
    
    /// Begins the CSV file by opening the output stream (if it wasn't already open).
    ///
    /// If you call this function a second (or more) times, an error will be thrown.
    /// There won't be any change in state, thus you could continue working as usual.
    /// - throws: `CSVWriter.Error` exclusively.
    public func beginFile() throws {
        guard case .initialized = self.state.file else {
            throw Error.invalidCommand(message: "The CSV writer has already been started.")
        }
        
        if case .notOpen = self.output.stream.streamStatus {
            self.output.stream.open()
        }
        
        guard case .open = self.output.stream.streamStatus else {
            throw Error.outputStreamFailed(message: "The stream couldn't be open.", underlyingError: output.stream.streamError)
        }
        
        if !self.settings.headers.isEmpty {
            self.state = (.initialized, .headers)
            try self.write(row: self.settings.headers)
        }

        self.state = (.started(nextIndex: 0), .unstarted)
}
    
    /// Starts a new CSV row.
    ///
    /// If a previous row was not "ended". This function will finish it (adding empty fields if less than expected amount of fields were provided).
    /// - throws: `CSVWriter.Error` exclusively.
    public func beginRow() throws {
        switch self.state.file {
        case .started:     try self.endRow()
        case .initialized: try beginFile()
        case .closed:      throw Error.invalidCommand(message: "A row cannot be started on a CSVWriter where endFile() has already been called.")
        }
        
        self.state.row = .started(nextIndex: 0)
    }
    
    /// Writes a `String` field into a CSV row.
    /// - parameter field: The `String` to concatenate to the current CSV row.
    /// - throws: `CSVWriter.Error` exclusively.
    public func write(field: String) throws {
        let fieldCount: Int
        
        switch self.state.file {
        case .started:
            switch self.state.row {
            case .started(let n):
                fieldCount = n
            case .headers:
                fieldCount = 0
                break;
            case .unstarted:
                fieldCount = 0
                self.state.row = .started(nextIndex: fieldCount)
            }
        case .initialized:
            try beginRow()
            fieldCount = 0
        case .closed:
            throw Error.invalidCommand(message: "A field cannot be writen on a CSVWriter where endFile() has already been called.")
        }
        
        if let expectedFields = self.expectedFieldsPerRow, fieldCount >= expectedFields {
            throw Error.invalidCommand(message: "The field \"\(field)\" cannot be added to the row, since only \(expectedFields) fields were expected. All CSV rows must have the same amount of fields.")
        }
        
        if fieldCount > 0 {
            try self.lowlevelWrite(delimiter: self.settings.delimiters.field)
        }
        
        try self.lowlevelWrite(field: field)
        self.state.row = .started(nextIndex: fieldCount + 1)
    }
    
    /// Finishes a row adding empty fields if fewer fields have been added as been expected.
    /// - throws: `CSVWriter.Error` exclusively.
    public func endRow() throws {
        let rowCount: Int
        switch self.state.file {
        case .started(let n): rowCount = n
        case .initialized:    throw Error.invalidCommand(message: "A row cannot be finished if the CSV file hasn't been started.")
        case .closed:         throw Error.invalidCommand(message: "A row cannot be finished on a CSVWriter where endFile() has already been called.")
        }
        
        // Check whether the row has previously been finished. If so, simply return.
        guard case .started(let fieldCount) = self.state.row else { return }
        
        if let expectedFields = self.expectedFieldsPerRow {
            guard fieldCount <= expectedFields else {
                throw Error.invalidInput(message: "\(expectedFields) fields were expected and \(fieldCount) fields were writen. All CSV rows must have the same amount of fields.")
            }
            
            if fieldCount < expectedFields {
                for index in fieldCount..<expectedFields {
                    if index > 0 {
                        try self.lowlevelWrite(delimiter: self.settings.delimiters.field)
                    }
                    try self.lowlevelWrite(field: "")
                    self.state.row = .started(nextIndex: index+1)
                }
            }
        } else {
            self.expectedFieldsPerRow = fieldCount
        }
        
        try self.lowlevelWrite(delimiter: self.settings.delimiters.row)
        self.state.row = .unstarted
        self.state.file = .started(nextIndex: rowCount + 1)
    }
    
    /// Finishes the file and closes the output stream (if not indicated otherwise in the initializer).
    /// - throws: `CSVWriter.Error.outputStreamFailed` exclusively when the stream is busy or cannot be closed.
    public func endFile() throws {
        let rowCount: Int
        
        switch self.state.file {
        case .initialized:
            self.state.file = .closed(rowCount: 0)
            return
        case .started(let n):
            try self.endRow()
            rowCount = n + 1
        case .closed:
            return
        }
        
        if self.output.closeAtEnd {
            guard case .open = self.output.stream.streamStatus else {
                throw Error.outputStreamFailed(message: "The stream couldn't be closed.", underlyingError: output.stream.streamError)
            }
            
            self.output.stream.close()
        }
        
        self.state.file = .closed(rowCount: rowCount)
    }
    
    /// Writes a sequence of `String`s as the fields of the new CSV row.
    ///
    /// Every time this is called, a new row will be created, completing any previous uncomplete one.
    /// - parameter row: A sequence representing a CSV row.
    /// - note: The row is not "completed" at the end of this call, so subsequent calls to `write(field:)` can be made.
    /// - throws: `CSVWriter.Error` exclusively.
    public func write<S:Sequence>(row: S) throws where S.Element == String {
        switch self.state.file {
        case .started:     try self.endRow()
        case .initialized:
            switch self.state.row {
            case .headers:
                break;
            default:
                try self.beginFile()
            }
        case .closed:      throw Error.invalidCommand(message: "A field cannot be writen on a CSVWriter where endFile() has already been called.")
        }

        var fieldCount = 0
        self.state.row = .started(nextIndex: fieldCount)
        
        for field in row {
            if let expectedFields = self.expectedFieldsPerRow, fieldCount + 1 > expectedFields {
                throw Error.invalidCommand(message: "The field \"\(field)\" cannot be added to the row, since only \(expectedFields) fields were expected. All CSV rows must have the same amount of fields.")
            }
            
            if fieldCount > 0 {
                try self.lowlevelWrite(delimiter: self.settings.delimiters.field)
            }
            try self.lowlevelWrite(field: field)
            
            fieldCount += 1
            self.state.row = .started(nextIndex: fieldCount)
        }
        
        try self.lowlevelWrite(delimiter: self.settings.delimiters.row)
    }
}

extension CSVWriter {
    /// Writes the given `String` into the receiving writer's stream.
    /// - throws: `CSVWriter.Error` if the operation failed.
    fileprivate func lowlevelWrite(field: String) throws {
        let escapingScalar = self.settings.escapingScalar
        var iterator = field.unicodeScalars.makeIterator()
        
        self.buffer.removeAll()
        var result: [Unicode.Scalar] = .init()
        var needsEscaping: Bool = false
        
        while let scalar = iterator.next() {
            result.append(scalar)
            
            guard scalar != escapingScalar else {
                needsEscaping = true
                result.append(escapingScalar)
                continue
            }
            
            guard !needsEscaping else { continue }
            
            if self.isFieldDelimiter(scalar, &iterator) || self.isRowDelimiter(scalar, &iterator) {
                needsEscaping = true
            }
            
            while let bufferedScalar = self.buffer.next() {
                result.append(bufferedScalar)
            }
        }
        
        if needsEscaping || result.isEmpty {
            result.append(escapingScalar)
            result.insert(escapingScalar, at: result.startIndex)
        }
        
        for scalar in result {
            try self.scalarWrite(scalar)
        }
    }
    
    /// Writes the given delimiter in the receiving writer's stream.
    /// - throws: `CSVWriter.Error` if the operation failed.
    fileprivate func lowlevelWrite(delimiter: String.UnicodeScalarView) throws {
        for scalar in delimiter {
            try self.scalarWrite(scalar)
        }
    }
    
    /// Writes the given scalar into the receiving writer's stream.
    ///
    /// To write the unicode scalar, first this is transformed into the configured encoding.
    /// - parameter scalar: The unicode scalar to write in the stream.
    /// - throws: `CSVWriter.Error` if the operation failed.
    private func scalarWrite(_ scalar: Unicode.Scalar) throws {
        try self.encoder(scalar) { [unowned stream = self.output.stream] (ptr, length) in
            var bytesLeft = length
            
            while true {
                switch stream.write(ptr, maxLength: bytesLeft) {
                case bytesLeft:
                    return
                case 0:
                    throw Error.outputStreamFailed(message: "The output stream has reached its capacity and it doesn't allow any more writes.", underlyingError: stream.streamError)
                case -1:
                    throw Error.outputStreamFailed(message: "The output stream failed while it was been writen to.", underlyingError: stream.streamError)
                case let bytesWriten:
                    bytesLeft -= bytesWriten
                    guard bytesLeft > 0 else {
                        throw Error.outputStreamFailed(message: "A failure occurred computing the amount of bytes to write.", underlyingError: nil)
                    }
                }
            }
        }
    }
}

extension CSVWriter {
    /// Closure accepting a scalar and returning a Boolean indicating whether the scalar (and subsquent unicode scalars) form a delimiter.
    fileprivate typealias DelimiterChecker = (_ scalar: Unicode.Scalar, _ iterator: inout String.UnicodeScalarView.Iterator) -> Bool

    /// Creates a delimiter identifier closure.
    fileprivate static func matchCreator(delimiter view: String.UnicodeScalarView, buffer: Buffer) -> DelimiterChecker  {
        // This should never be triggered.
        precondition(!view.isEmpty, "Delimiters must include at least one unicode scalar.")

        // For optimization sake, a delimiter proofer is built for a unique single unicode scalar.
        if view.count == 1 {
            let delimiter = view.first!
            return { (scalar, _) in delimiter == scalar }
        // For optimizations sake, a delimiter proofer is built for two unicode scalars.
        } else if view.count == 2 {
            let firstDelimiter = view.first!
            let secondDelimiter = view[view.index(after: view.startIndex)]
            
            return { (firstScalar, iterator) in
                guard firstDelimiter == firstScalar, let secondScalar = buffer.next() ?? iterator.next() else {
                    return false
                }
                
                buffer.preppend(scalar: secondScalar)
                return secondDelimiter == secondScalar
            }
        // For completion sake, a delimiter proofer is build for +2 unicode scalars.
        // CSV files with multiscalar delimiters are very very rare (if non-existant).
        } else {
            return { (firstScalar, iterator) in
                var scalar = firstScalar
                var index = view.startIndex
                var toIncludeInBuffer: [Unicode.Scalar] = .init()
                defer {
                    if !toIncludeInBuffer.isEmpty {
                        buffer.preppend(scalars: toIncludeInBuffer)
                    }
                }
                
                while true {
                    guard scalar == view[index] else { return false }
                    
                    index = view.index(after: index)
                    guard index < view.endIndex else { return true }
                    
                    guard let nextScalar = buffer.next() ?? iterator.next() else { return false }
                    
                    toIncludeInBuffer.append(nextScalar)
                    scalar = nextScalar
                }
            }
        }
    }
}
