import Foundation

/// Sequentially writes string values and/or array of strings into a CSV file format.
public final class CSVWriter {
    /// Recipe detailing how to write the CSV information (i.e. delimiters, date strategy, etc.).
    public let configuration: Configuration
    /// Internal writer settings extracted from the public `configuration` and other values inferred during initialization.
    internal let settings: Settings
    ///
    private let stream: OutputStream
    /// Encoder used to transform unicode scalars into a bunch of bytes and store them in the result
    private let encoder: ScalarEncoder
    /// Check whether the following scalars are part of the field delimiter sequence.
    private let isFieldDelimiter: DelimiterChecker
    /// Check whether the following scalar are par of the row delimiter sequence.
    private let isRowDelimiter: DelimiterChecker
    
    
//    /// The number of fields per row that are expected.
//    private(set) internal var expectedFieldsPerRow: Int?
//    /// The writer state indicating whether it has already begun working or it is idle.
//    private var state: (file: State.File, row: State.Row)

    /// Designated initializer for the CSV writer.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - parameter stream: An output stream that is already open.
    /// - parameter encoder: The function transforming unicode scalars into the desired binary representation and storing the bytes in their final location.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    internal init(configuration: Configuration, settings: Settings, stream: OutputStream, encoder: @escaping ScalarEncoder) throws {
        precondition(stream.streamStatus != .notOpen)
        self.configuration = configuration
        self.settings = settings
        (self.stream, self.encoder) = (stream, encoder)
        self.isFieldDelimiter = CSVWriter.makeMatcher(delimiter: self.settings.delimiters.field)
        self.isRowDelimiter = CSVWriter.makeMatcher(delimiter: self.settings.delimiters.row)
    }
    
//    internal init(output: (stream: OutputStream, closeAtEnd: Bool), configuration: Configuration, encoder: @escaping Unicode.Scalar.Encoder) throws {
//        self.settings = try Settings(configuration: configuration)
//
//        self.output = (output.stream, output.closeAtEnd)
//        self.expectedFieldsPerRow = nil
//        self.state = (.unbegun, .unstarted)
//    }

    deinit {
        try? self.endFile()
    }

//    /// The encoding position; a.k.a. the row and field index to write next.
//    ///
//    /// Every time a row is fully writen, the row index gets bumped by 1. But note that the header row is not accounted on the `row` index.
//    /// - note: If the `CSVWriter` is appending rows to a previously writen file/socket, those rows are not accounted for.
//    public var indices: (row: Int, field: Int) {
//        switch state.file {
//        case .unbegun:              return (0, 0)
//        case .active(let rowIndex): return (rowIndex, self.state.row.nextIndex)
//        case .closed(let rowIndex): return (rowIndex, 0)
//        }
//    }
//
//    /// Returns the generated blob of data if the writer was initialized with a memory position (not a file nor a network socket).
//    /// - remark: Please notice that the `endFile()` function must be called before this property is used. If not, `nil` will be returned.
//    public var dataInMemory: Data? {
//        guard case .closed = self.state.file else { return nil }
//        return self.output.stream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data
//    }
    
    public func data() throws -> Data {
        fatalError()
        
//        stream.close()
//        guard let data = stream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data,
//            let result = String(data: data, encoding: encoding) else {
//                fatalError()
//        }
    }
}

extension CSVWriter {
//    /// Begins the CSV file by opening the output stream (if it wasn't already open).
//    ///
//    /// If you call this function a second time, an `CSWriter.Error.invalidCommand` error will be thrown.
//    /// - parameter bom: If not `nil` the provided Byte Order Marker will be writen at the beginning of the file.
//    /// - parameter writeHeaders: Boolean indicating whether the headers should be writen.
//    /// - throws: `CSVWriter.Error` exclusively.
//    internal func beginFile(bom: [UInt8]?, writeHeaders: Bool) throws {
//        guard case .unbegun = self.state.file else {
//            throw Error.invalidCommand("The CSV writer has already been started.")
//        }
//
//        if case .notOpen = self.output.stream.streamStatus {
//            self.output.stream.open()
//        }
//
//        guard case .open = self.output.stream.streamStatus else {
//            throw Error.outputStreamFailed("The stream couldn't be open.", underlyingError: output.stream.streamError)
//        }
//
//        if let bom = bom {
//            self.output.stream.write(bom, maxLength: bom.count)
//        }
//
//        self.state = (.active(nextIndex: 0), .unstarted)
//        guard writeHeaders, !self.settings.headers.isEmpty else { return }
//
//        try self.write(row: self.settings.headers)
//        self.state = (.active(nextIndex: 0), .unstarted)
//    }
//
    /// Finishes the file and closes the output stream (if not indicated otherwise in the initializer).
//    /// - throws: `CSVWriter.Error.outputStreamFailed` exclusively when the stream is busy or cannot be closed.
    public func endFile() throws {
//        let rowCount: Int
//
//        switch self.state.file {
//        case .unbegun:
//            self.state = (.closed(rowCount: 0), .unstarted)
//            return
//        case .active(let n):
//            try self.endRow()
//            rowCount = n + 1
//        case .closed: return
//        }
//
//        if self.output.closeAtEnd {
//            guard case .open = self.output.stream.streamStatus else {
//                throw Error.outputStreamFailed("The stream couldn't be closed.", underlyingError: output.stream.streamError)
//            }
//
//            self.output.stream.close()
//        }
//
//        self.state.file = .closed(rowCount: rowCount)
    }
}

//extension CSVWriter {
//    /// Writes a `String` field into a CSV row.
//    /// - parameter field: The `String` to concatenate to the current CSV row.
//    /// - throws: `CSVWriter.Error` exclusively.
//    public func write(field: String) throws {
//        guard case .active = self.state.file else {
//            throw Error.invalidCommand("A field cannot be writen on an inactive file (i.e. a file which hasn't begun or it has already been closed).")
//        }
//
//        let fieldCount: Int
//        switch self.state.row {
//        case .active(let n): fieldCount = n
//        case .unstarted:     fieldCount = 0
//            self.state.row = .active(nextIndex: fieldCount)
//        }
//
//        if let expectedFields = self.expectedFieldsPerRow, fieldCount >= expectedFields {
//            throw Error.invalidCommand("The field '\(field)' cannot be added to the row, since only \(expectedFields) fields were expected. All CSV rows must have the same amount of fields.")
//        }
//
//        if fieldCount > 0 {
//            try self.lowlevelWrite(delimiter: self.settings.delimiters.field)
//        }
//
//        try self.lowlevelWrite(field: field)
//        self.state.row = .active(nextIndex: fieldCount + 1)
//    }
//
//    /// Appends a sequence of `String`s as the fields of the current CSV row.
//    ///
//    /// This function can be called to add several fields at the same time. The row is not completed at the end of this function; therefore subsequent calls to this function or `write(field:)` can be made.
//    /// An explicit call to `endRow()` must be made to write the row delimiter.
//    /// - parameter fields: A sequence representing several fields.
//    /// - throws: `CSVWriter.Error` exclusively.
//    public func write<S:Sequence>(fields: S) throws where S.Element == String {
//        guard case .active = self.state.file else {
//            throw Error.invalidCommand("A field cannot be writen on an inactive file (i.e. a file which hasn't begun or it has already been closed).")
//        }
//
//        var fieldCount: Int
//        switch self.state.row {
//        case .unstarted:
//            fieldCount = 0
//            self.state.row = .active(nextIndex: fieldCount)
//        case .active(let n):
//            fieldCount = n
//        }
//
//        for field in fields {
//            if let expectedFields = self.expectedFieldsPerRow, fieldCount + 1 > expectedFields {
//                throw Error.invalidCommand("The field '\(field)' cannot be added to the row, since only \(expectedFields) fields were expected. All CSV rows must have the same amount of fields.")
//            }
//
//            if fieldCount > 0 {
//                try self.lowlevelWrite(delimiter: self.settings.delimiters.field)
//            }
//            try self.lowlevelWrite(field: field)
//
//            fieldCount += 1
//            self.state.row = .active(nextIndex: fieldCount)
//        }
//    }
//
//    /// Finishes a row adding empty fields if fewer fields than expected have been writen.
//    ///
//    /// It is perfectly fine to call this method when only some fields (but not all) have been writen. This function will complete the row writing row delimiters.
//    /// - throws: `CSVWriter.Error` exclusively.
//    public func endRow() throws {
//        guard case .active(let rowCount) = self.state.file else {
//            throw Error.invalidCommand("A row cannot be finished if the CSV file is inactive (i.e. a file which hasn't begun or it has already been closed).")
//        }
//
//        // If the row is already completed (i.e. the row delimiter has been writen), no more work needs to be done.
//        guard case .active(let fieldCount) = self.state.row else { return }
//
//        // Calculate if there are more fields left to write (in which case empty fields with delimiters are writen).
//        if let expectedFields = self.expectedFieldsPerRow {
//            guard fieldCount <= expectedFields else {
//                throw Error.invalidInput("\(expectedFields) fields were expected and \(fieldCount) fields were writen. All CSV rows must have the same amount of fields.")
//            }
//
//            if fieldCount < expectedFields {
//                for index in fieldCount..<expectedFields {
//                    if index > 0 {
//                        try self.lowlevelWrite(delimiter: self.settings.delimiters.field)
//                    }
//                    try self.lowlevelWrite(field: "")
//                    self.state.row = .active(nextIndex: index+1)
//                }
//            }
//        } else {
//            self.expectedFieldsPerRow = fieldCount
//        }
//
//        try self.lowlevelWrite(delimiter: self.settings.delimiters.row)
//        self.state = (.active(nextIndex: rowCount + 1), .unstarted)
//    }
//}
//
extension CSVWriter {
//    /// Writes a sequence of `String`s as fields of a brand new row and then ends the row (by writing a delimiter).
//    ///
//    /// Do not call `endRow()` after this function. It is called internally.
//    /// - parameter row: Sequence of strings representing a CSV row.
//    /// - throws: `CSVWriter.Error` exclusively.
    public func write<S:Sequence>(row: S) throws where S.Element==String {
//        guard case .unstarted = self.state.row else {
//            throw Error.invalidCommand("A row cannot be written if the previous one hasn't yet been closed.")
//        }
//
//        try self.write(fields: row)
//        try self.endRow()
    }
//
//    /// Writes an empty CSV row.
//    ///
//    /// An empty row is just comprise internally of the required field delimiters and a row delimiter.
//    /// - remark: An empty row cannot start a CSV file if such file has no headers, since the number of fields wouldn't be known.
//    /// - throws: `CSVWriter.Error` exclusively.
//    public func writeEmptyRow() throws {
//        guard case .active(let rowCount) = self.state.file else {
//            throw Error.invalidCommand("A row cannot be writen on an inactive file (i.e. a file which hasn't begun or it has already been closed).")
//        }
//
//        guard case .unstarted = self.state.row else {
//            throw Error.invalidCommand("A row cannot be written if the previous one hasn't yet been closed.")
//        }
//
//        guard let expectedFields = self.expectedFieldsPerRow else {
//            throw Error.invalidCommand("An empty row cannot be writen if the number of fields hold by the file is unkwnown.")
//        }
//
//        self.state.row = .active(nextIndex: 0)
//        for index in 0..<expectedFields {
//            if index > 0 {
//                try self.lowlevelWrite(delimiter: self.settings.delimiters.field)
//            }
//            try self.lowlevelWrite(field: "")
//            self.state.row = .active(nextIndex: index+1)
//        }
//
//        try self.lowlevelWrite(delimiter: self.settings.delimiters.row)
//        self.state = (.active(nextIndex: rowCount + 1), .unstarted)
//    }
}

// MARK: -

extension CSVWriter {
    /// Writes the given `String` into the receiving writer's stream.
    /// - parameter field: The field to be checked for characters to escape and subsequently written.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    private func lowlevelWrite(field: String) throws {
        let escapingScalar = self.settings.escapingScalar
        var result: [Unicode.Scalar]
        
        if field.isEmpty {
            result = .init(repeating: escapingScalar, count: 2)
        } else {
            let input: [Unicode.Scalar] = .init(field.unicodeScalars)
            result = .init()
            result.reserveCapacity(input.count + 2)
            var (index, needsEscaping) = (0, false)
            
            while index < input.endIndex {
                let scalar = input[index]
                
                if scalar == escapingScalar {
                    needsEscaping = true
                } else if self.isFieldDelimiter(input, &index, &result) || self.isRowDelimiter(input, &index, &result) {
                    needsEscaping = true
                    continue
                }
                
                index += 1
                result.append(scalar)
            }
            
            if needsEscaping {
                result.insert(escapingScalar, at: result.startIndex)
                result.append(escapingScalar)
            }
        }

        try result.forEach { try self.encoder($0) }
    }
}

fileprivate extension CSVWriter.Error {
}
