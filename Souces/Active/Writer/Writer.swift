import Foundation

/// Sequentially writes string values and/or array of strings into a CSV file format.
public final class CSVWriter {
    /// Generic configuration variables for the writer.
    public let configuration: CSV.Configuration
    /// Specific configuration variables for these CSV writing passes.
    fileprivate var internals: CSVWriter.Configuration
    /// The output stream holding the writing data blob.
    fileprivate let output: (stream: OutputStream, closeAtEnd: Bool)
    /// Encoder used to transform unicode scalars into a bunch of bytes.
    fileprivate let encoder: Unicode.Scalar.Encoder
    /// The number of fields per row that are expected.
    fileprivate var expectedFieldsPerRow: Int?
    /// The writer state indicating whether it has already begun working or it is idle.
    fileprivate var state: (file: State.File, row: State.Row)
    
    /// Designated initializer
    internal init(output: (stream: OutputStream, closeAtEnd: Bool), configuration: CSV.Configuration, encoder: @escaping Unicode.Scalar.Encoder) throws {
        self.configuration = configuration
        self.internals = try Configuration(configuration: configuration)
        self.output = (output.stream, output.closeAtEnd)
        self.encoder = encoder
        self.expectedFieldsPerRow = nil
        self.state = (.initialized, .finished)
    }
    
    deinit {
        try? self.endFile()
    }
    
    /// Begins the CSV file by opening the output stream (if it wasn't already open).
    /// - warning: Never call `begin` functions more than once.
    /// - throws: `CSVWriter.Error` exclusively.
    public func beginFile() throws {
        guard case .initialized = self.state.file else {
            throw Error.invalidInput(message: "The CSV writer must only be started/begun once.")
        }
        
        if case .notOpen = self.output.stream.streamStatus {
            self.output.stream.open()
        }
        
        guard case .open = self.output.stream.streamStatus else {
            throw Error.outputStreamFailed(message: "The stream couldn't be open.", underlyingError: output.stream.streamError)
        }
        
        self.state.file = .started
    }
    
    /// Begins the CSV file by opening the output stream (if it wasn't already open) and optionally write the headers as the first line.
    /// - warning: Never call this function more than once.
    /// - parameter headers: Optional header row to add at the beginning of the file.
    /// - throws: `CSVWriter.Error` exclusively.
    public func beginFile<S:Sequence>(headers: S) throws where S.Element == String {
        if case .some(let hasHeaders) = self.internals.hasHeader, hasHeaders == false {
            throw Error.invalidCommand(message: "The configuration specify that no headers will be written into the CSV file, however a header was provided.")
        }
        
        try self.beginFile()
        
        self.internals.hasHeader = true
        try self.write(row: headers)
    }
    
    /// Starts a new CSV row.
    ///
    /// If a previous row was not "ended". This function will finish it (adding empty fields if less than expected amount of fields were provided).
    /// - throws: `CSVWriter.Error` exclusively.
    public func beginRow() throws {
        switch self.state.file {
        case .started: try self.endRow()
        case .initialized: try beginFile()
        case .closed: throw Error.invalidCommand(message: "A row cannot be started on a CSVWriter where endFile() has already been called.")
        }
        
        self.state.row = .started(writenFields: 0)
    }
    
    /// Writes a `String` field into a CSV row.
    /// - parameter field: The `String` to concatenate to the current CSV row.
    /// - throws: `CSVWriter.Error` exclusively.
    public func write(field: String) throws {
        switch self.state.file {
        case .started: break
        case .initialized: throw Error.invalidCommand(message: "A field cannot be writen if the CSV file hasn't been started.")
        case .closed: throw Error.invalidCommand(message: "A field cannot be writen on a CSVWriter where endFile() has already been called.")
        }
        
        let fieldsSoFar: Int
        
        switch self.state.row {
        case .finished:
            self.state.row = .started(writenFields: 0)
            fieldsSoFar = 0
        case .started(let writenFields):
            fieldsSoFar = writenFields
        }
        
        if let expectedFields = self.expectedFieldsPerRow, fieldsSoFar >= expectedFields {
            throw Error.invalidCommand(message: "The field \"\(field)\" cannot be added to the row, since only \(expectedFields) fields were expected. All CSV rows must have the same amount of fields.")
        }
        
        if fieldsSoFar != 0 {
            try self.lowlevelWrite(delimiter: self.internals.delimiters.field)
        }
        try self.lowlevelWrite(field: field)
        self.state.row = .started(writenFields: fieldsSoFar + 1)
    }
    
    /// Finishes a row adding empty fields if fewer fields have been added as been expected.
    /// - throws: `CSVWriter.Error` exclusively.
    public func endRow() throws {
        switch self.state.file {
        case .started: break
        case .initialized: throw Error.invalidCommand(message: "A row cannot be finished if the CSV file hasn't been started.")
        case .closed: throw Error.invalidCommand(message: "A row cannot be finished on a CSVWriter where endFile() has already been called.")
        }
        
        // Check whether the row has previously been finished.
        guard case .started(let writenFields) = self.state.row else { return }
        
        if let expectedFields = self.expectedFieldsPerRow {
            guard writenFields <= expectedFields else {
                throw Error.invalidInput(message: "\(expectedFields) fields were expected and \(writenFields) fields were writen. All CSV rows must have the same amount of fields.")
            }
            
            if writenFields < expectedFields {
                for index in writenFields..<expectedFields {
                    if index != 0 {
                        try self.lowlevelWrite(delimiter: self.internals.delimiters.field)
                    }
                    try self.lowlevelWrite(field: "")
                }
            }
        } else {
            self.expectedFieldsPerRow = writenFields
        }
        
        try self.lowlevelWrite(delimiter: self.internals.delimiters.row)
        self.state.row = .finished
    }
    
    /// Finishes the file and closes the output stream (if not indicated otherwise in the initializer).
    /// - throws: `CSVWriter.Error.outputStreamFailed` exclusively when the stream is busy or cannot be closed.
    public func endFile() throws {
        switch self.state.file {
        case .initialized: self.state.file = .closed; return
        case .started: try self.endRow()
        case .closed: return
        }
        
        if output.closeAtEnd {
            guard case .open = self.output.stream.streamStatus else {
                throw Error.outputStreamFailed(message: "The stream couldn't be closed.", underlyingError: output.stream.streamError)
            }
            
            self.output.stream.close()
        }
        
        self.state.file = .closed
    }
    
    /// Writes a sequence of `String` as the fields of the new CSV row.
    ///
    /// Remember, that the
    /// - throws: `CSVWriter.Error` exclusively.
    public func write<S:Sequence>(row: S) throws where S.Element == String {
        switch self.state.file {
        case .started: break
        case .initialized: try beginFile()
        case .closed: throw Error.invalidCommand(message: "A field cannot be writen on a CSVWriter where endFile() has already been called.")
        }
        
        var writenFields = 0
        self.state.row = .started(writenFields: writenFields)
        
        for field in row {
            if let expectedFields = self.expectedFieldsPerRow, writenFields + 1 > expectedFields {
                throw Error.invalidCommand(message: "The field \"\(field)\" cannot be added to the row, since only \(expectedFields) fields were expected. All CSV rows must have the same amount of fields.")
            }
            
            if writenFields != 0 {
                try self.lowlevelWrite(delimiter: self.internals.delimiters.field)
            }
            try self.lowlevelWrite(field: field)
            
            writenFields += 1
            self.state.row = .started(writenFields: writenFields)
        }
        
        try self.lowlevelWrite(delimiter: self.internals.delimiters.row)
        self.state.row = .finished
    }
}

extension CSVWriter {
    ///
    fileprivate func lowlevelWrite(field: String) throws {
        #warning("TODO: Algorithm")
    }
    
    ///
    fileprivate func lowlevelWrite(delimiter: String.UnicodeScalarView) throws {
        for scalar in delimiter {
            try self.scalarWrite(scalar)
        }
    }
    
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
