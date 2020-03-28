extension ShadowEncoder {
    /// Sink of all CSV data.
    internal final class Sink {
        /// The instance writing the CSV data.
        private let writer: CSVWriter
        /// The rows buffer.
        private let buffer: Buffer
        /// The decoding configuration.
        let configuration: CSVEncoder.Configuration
        /// Any contextual information set by the user for decoding.
        let userInfo: [CodingUserInfoKey:Any]
        /// Lookup dictionary providing fast index discovery for header names.
        private var headerLookup: [Int:Int]
        
        /// Creates the unique data sink for the encoding process.
        init(writer: CSVWriter, configuration: CSVEncoder.Configuration, userInfo: [CodingUserInfoKey:Any]) throws {
            self.writer = writer
            self.buffer = Buffer(strategy: configuration.bufferingStrategy)
            self.configuration = configuration
            self.userInfo = userInfo
            self.headerLookup = .init()
        }
    }
}

extension ShadowEncoder.Sink {
    /// The number of fields expected per row.
    ///
    /// If zero, it means the expectation has not yet being set.
    var numExpectedFields: Int {
        self.writer.expectedFields
    }
    
    /// Returns the number of rows that have been sent to this *sink*.
    ///
    /// The rows might not yet be fully encoded (i.e. written in their binary format).
    var numEncodedRows: Int {
        self.writer.rowIndex + self.buffer.count
    }
    
    /// Returns the number of fields within the given row, which have been sent to this *sink*.
    ///
    /// The fields might not yet be fully encoded (i.e. written in their binary format).
    func numEncodedFields(at rowIndex: Int) -> Int {
        if rowIndex < self.writer.rowIndex {
            return self.writer.expectedFields
        } else if rowIndex == self.writer.rowIndex {
            return max(self.writer.fieldIndex, self.buffer.fieldCount(forRowIndex: rowIndex))
        } else {
            return self.buffer.fieldCount(forRowIndex: rowIndex)
        }
    }
    
    /// Returns the field index for the given coding key.
    ///
    /// This function first tries to extract the integer value from the key and if unavailable, the string value is extracted and matched against the CSV headers.
    /// - parameter key: The coding key representing the field's position within a row, or the field's name within the headers row.
    /// - returns: The position of the field within the row.
    func fieldIndex(forKey key: CodingKey, codingPath: [CodingKey]) throws -> Int {
        if let index = key.intValue { return index }
        
        let name = key.stringValue
        if self.headerLookup.isEmpty {
            guard !self.configuration.headers.isEmpty else { throw CSVEncoder.Error.emptyHeader(key: key, codingPath: codingPath) }
            self.headerLookup = try self.configuration.headers.lookupDictionary(onCollision: { CSVEncoder.Error.invalidHashableHeader() })
        }
        
        return try self.headerLookup[name.hashValue] ?! CSVEncoder.Error.unmatchedHeader(forKey: key, codingPath: codingPath)
    }
    
    /// Encodes the given field in the given position.
    func field(value: String, at rowIndex: Int, _ fieldIndex: Int) throws {
        // 1. Check the given row index is matching the row to be written by the writer.
        guard self.writer.rowIndex == rowIndex else {
            // 1.1. If not, the row must not have been written already (otherwise an error is thrown).
            guard self.writer.rowIndex > rowIndex else { throw CSVEncoder.Error.writingSurpassed(rowIndex: rowIndex, fieldIndex: fieldIndex, value: value) }
            // 1.2. If the row hasn't been writen yet, store it in the buffer.
            return self.buffer.store(value: value, at: rowIndex, fieldIndex)
        }
        
        // 2. Check the field index is matching the field to be written by the writer.
        guard self.writer.fieldIndex == fieldIndex else {
            // 2.1 If not, the field must not have been written already (otherwise an error is thrown).
            guard self.writer.fieldIndex > fieldIndex else { throw CSVEncoder.Error.writingSurpassed(rowIndex: rowIndex, fieldIndex: fieldIndex, value: value) }
            // 2.2 If the field hasn't been writen yet, store it in the buffer.
            return self.buffer.store(value: value, at: rowIndex, fieldIndex)
        }
        
        // 3. This point is only reached if the writer is going to write the provided field next.
        try self.writer.write(field: value)
        // 4.
        #warning("TODO: Continue here") // Call next() on buffer returning an element and a boolean indicating whether it is the end of the row.
//        if self.writer.fieldIndex == self.writer.expectedFields {
//            try self.writer.endRow()
//        }
    }
}

fileprivate extension CSVEncoder.Error {
    /// The provided coding key couldn't be mapped into a concrete index since there is no CSV header.
    static func emptyHeader(key: CodingKey, codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidConfiguration,
              reason: "The provided coding key identifying a field cannot be matched to a header, since the CSV file has no headers.",
              help: "Make the key generate an integer value or provide header during configuration.",
              userInfo: ["Key": key, "Coding path": codingPath])
    }
    /// Error raised when a record is fetched, but there are header names which has the same hash value (i.e. they have the same name).
    static func invalidHashableHeader() -> CSVError<CSVEncoder> {
        .init(.invalidConfiguration,
              reason: "The header row contain two fields with the same value.",
              help: "Request a row instead of a record.")
    }
    /// The provided coding key couldn't be mapped into a concrete index since it didn't match any header field.
    static func unmatchedHeader(forKey key: CodingKey, codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidConfiguration,
              reason: "The provided coding key identifying a field didn't match any CSV header.",
              help: "Make the key generate an integer value or provide a matching header.",
              userInfo: ["Key": key, "Coding path": codingPath])
    }
    /// Error raised when the coding path provided points to a row/field that has already been written.
    static func writingSurpassed(rowIndex: Int, fieldIndex: Int, value: String) -> CSVError<CSVEncoder> {
        .init(.invalidPath,
              reason: "The provided coding path matched a previously written field.",
              help: "An already written CSV row cannot be rewritten. Be mindful on the encoding order.",
              userInfo: ["Row index": rowIndex, "Field index": fieldIndex, "Value": value])
    }
}
