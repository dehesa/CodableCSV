import Foundation

internal extension ShadowEncoder {
    /// Sink of all CSV data.
    final class Sink {
        /// The instance writing the CSV data.
        private let _writer: CSVWriter
        /// The rows buffer.
        private let _buffer: Buffer
        /// The decoding configuration.
        let configuration: CSVEncoder.Configuration
        /// Any contextual information set by the user for decoding.
        let userInfo: [CodingUserInfoKey:Any]
        /// Lookup dictionary providing fast index discovery for header names.
        private var _headerLookup: [Int:Int]
        /// Encodes the given field in the given position.
        let fieldValue: (_ value: String, _ rowIndex: Int, _ fieldIndex: Int) throws -> Void
        
        /// Creates the unique data sink for the encoding process.
        init(writer: CSVWriter, configuration: CSVEncoder.Configuration, userInfo: [CodingUserInfoKey:Any]) throws {
            self._writer = writer
            
            let strategy: Strategy.EncodingBuffer
            switch configuration.bufferingStrategy {
            case .assembled where configuration.headers.isEmpty: strategy = .keepAll
            case let others: strategy = others
            }
            
            self._buffer = Buffer(strategy: strategy, expectedFields: self._writer.expectedFields)
            self.configuration = configuration
            self.userInfo = userInfo
            self._headerLookup = .init()
            
            switch strategy {
            case .keepAll:
                self.fieldValue = { [unowned buffer = self._buffer] in
                    // A.1. Just store the field in the buffer and forget till completion.
                    buffer.store(value: $0, at: $1, $2)
                }
                
            case .assembled:
                self.fieldValue = { [unowned buffer = self._buffer, unowned writer = self._writer] in
                    // B.1. Is the requested row the same as the writer's row focus?
                    guard writer.rowIndex == $1 else {
                        // B.1.1. If not, the row must not have been written yet (otherwise an error is thrown).
                        guard $1 > writer.rowIndex else { throw CSVEncoder.Error._writingSurpassed(rowIndex: $1, fieldIndex: $2, value: $0) }
                        // B.1.2. If the row hasn't been writen yet, store it in the buffer.
                        return buffer.store(value: $0, at: $1, $2)
                    }
                    // B.2. Is the requested field the same as the writer's field focus?
                    guard writer.fieldIndex == $2 else {
                        // B.2.1 If not, the field must not have been written yet (otherwise an error is thrown).
                        guard $2 > writer.fieldIndex else { throw CSVEncoder.Error._writingSurpassed(rowIndex: $1, fieldIndex: $2, value: $0) }
                        // B.2.2 If the field hasn't been writen yet, store it in the buffer.
                        return buffer.store(value: $0, at: $1, $2)
                    }
                    // B.3. Write the provided field since it is the same as the writer's row/field.
                    try writer.write(field: $0)
                    
                    assert(writer.expectedFields > 0)
                    // B.4. Are there subsequent fields in the buffer?
                    while true {
                        // B.5. If is not the end of the row, check the buffer and see whether the following fields are already cached.
                        while writer.fieldIndex < writer.expectedFields {
                            guard let field = buffer.retrieveField(at: writer.rowIndex, writer.fieldIndex) else { return }
                            try writer.write(field: field)
                        }
                        // B.6. If it is the end of the row, write the row delimiter and continue with the next row.
                        try writer.endRow()
                    }
                }
                
            case .sequential:
                self.fieldValue = { [unowned buffer = self._buffer, unowned writer = self._writer] in
                    switch $1 {
                    // C.1. If the requested row is the same as the writer's row, break the switch clause.
                    case writer.rowIndex: break
                    // C.2. If the requested row is further on the CSV file...
                    case let rowIndex where writer.rowIndex < rowIndex:
                        // C.2.1. Check if the buffer has any more fields to write for the writer's row.
                        if var row = buffer.retrieveRow(at: rowIndex) {
                            // C.2.2. Iterate through all the stored fields (in order).
                            while let field = row.next() {
                                // C.2.3. If the writer's field is further back from the next remaining field. Write with empty fields.
                                while writer.fieldIndex < field.index { try writer.write(field: "") }
                                // C.2.5. Write the targeted field.
                                try writer.write(field: field.value)
                            }
                            // C.2.6 Finish the writer's row.
                            try writer.endRow()
                        }
                        // C.2.7. Write empty rows for rows between the writer's row and the user's targeted row.
                        while writer.rowIndex < rowIndex { try writer.endRow() }
                    // C.3. If the requested row has already been written, throw an error.
                    default: throw CSVEncoder.Error._writingSurpassed(rowIndex: $1, fieldIndex: $2, value: $0)
                    }
                    
                    // C.4. Is the requested field the same as the writer's field focus?
                    guard writer.fieldIndex == $2 else {
                        // C.4.1 If not, the field must not have been written yet (otherwise an error is thrown).
                        guard writer.fieldIndex > $2 else { throw CSVEncoder.Error._writingSurpassed(rowIndex: $1, fieldIndex: $2, value: $0) }
                        // C.4.2 If the field hasn't been writen yet, store it in the buffer.
                        return buffer.store(value: $0, at: $1, $2)
                    }
                    // C.6. Write the provided field since it is the same as the writer's row/field.
                    try writer.write(field: $0)
                }
                
            }
        }
        
        deinit {
            try? self.completeEncoding()
        }
    }
}

extension ShadowEncoder.Sink {
    /// The number of fields expected per row.
    ///
    /// If zero, it means the expectation has not yet being set.
    var numExpectedFields: Int {
        self._writer.expectedFields
    }
    
    /// Returns the number of rows that have been sent to this _sink_.
    ///
    /// The rows might not yet be fully encoded (i.e. written in their binary format).
    var numEncodedRows: Int {
        self._writer.rowIndex + self._buffer.count
    }
    
    /// Returns the number of fields within the given row, which have been sent to this _sink_.
    ///
    /// The fields might not yet be fully encoded (i.e. written in their binary format).
    func numEncodedFields(at rowIndex: Int) -> Int {
        // 1. If the requested row has already been writen, it can be safely assumed that all the fields were written.
        if rowIndex < self._writer.rowIndex {
            return self._writer.expectedFields
        // 2. If the row index is the same as the one being targeted by the writer, the number is the sum of the writer and the buffer.
        } else if rowIndex == self._writer.rowIndex {
            return self._writer.fieldIndex + self._buffer.fieldCount(for: rowIndex)
        // 3. If the row hasn't been written yet, query the buffer.
        } else {
            return self._buffer.fieldCount(for: rowIndex)
        }
    }
    
    /// Returns the field index for the given coding key.
    ///
    /// This function first tries to extract the integer value from the key and if unavailable, the string value is extracted and matched against the CSV headers.
    /// - parameter key: The coding key representing the field's position within a row, or the field's name within the headers row.
    /// - returns: The position of the field within the row.
    func fieldIndex(forKey key: CodingKey, codingPath: [CodingKey]) throws -> Int {
        // 1. If the key can be transformed into an integer, prefer that.
        if let index = key.intValue { return index }
        // 2. If not, extract the header name from the key.
        let name = key.stringValue
        // 3. Get the header lookup dictionary (building it if it is the first time accessing it).
        if self._headerLookup.isEmpty {
            guard !self.configuration.headers.isEmpty else { throw CSVEncoder.Error._emptyHeader(forKey: key, codingPath: codingPath) }
            self._headerLookup = try self.configuration.headers.lookupDictionary(onCollision: CSVEncoder.Error._invalidHashableHeader)
        }
        // 4. Get the index from the header lookup up and the header name.
        guard let index = self._headerLookup[name.hashValue] else {
            throw CSVEncoder.Error._unmatchedHeader(forKey: key, codingPath: codingPath)
        }
        return index
    }
    
    /// Finishes the whole encoding operation by commiting to the writer any remaining row/field in the buffer.
    ///
    /// This function works even when the number of fields per row are unknown.
    func completeEncoding() throws {
        // 1. Remove from the buffer the rows/fields from the writer point.
        var remainings = self._buffer.retrieveAll()
        // 2. Check whether there is any remaining row whatsoever.
        if let firstIndex = remainings.firstIndex {
            // 3. The first indeces must be the same or greater than the writer ones.
            guard firstIndex.row >= self._writer.rowIndex, firstIndex.field >= self._writer.fieldIndex else { throw CSVEncoder.Error._corruptedBuffer() }
            // 4. Iterate through all the remaining rows.
            while var row = remainings.next() {
                // 5. If the writer is further back from the next remaining row. Fill the writer with empty rows.
                while self._writer.rowIndex < row.index { try self._writer.endRow() }
                // 6. Iterate through all the fields in the row.
                while let field = row.next() {
                    // 7. If the row is further back from the next remaining field. Fill the writer with empty fields.
                    while self._writer.fieldIndex < field.index { try self._writer.write(field: "") }
                    // 8. Write the targeted field.
                    try self._writer.write(field: field.value)
                }
                // 9. Finish the targeted row.
                try self._writer.endRow()
            }
        }
        // 10. Finish the file.
        try self._writer.endEncoding()
    }
    
    /// Returns the generated blob of data if the `_writer` was initialized with a memory position (i.e. `String` or `Data`, but not a file nor a network socket).
    /// - remark: Please notice that the `endEncoding()` function must be called before this function is used.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    public func data() throws -> Data {
        try self._writer.data()
    }
}

fileprivate extension CSVEncoder.Error {
    /// Error raised when the coding path provided points to a row/field that has already been written.
    static func _writingSurpassed(rowIndex: Int, fieldIndex: Int, value: String) -> CSVError<CSVEncoder> {
        .init(.invalidPath,
              reason: "The provided coding path matched a previously written field.",
              help: "An already written CSV row cannot be rewritten. Be mindful on the encoding order.",
              userInfo: ["Row index": rowIndex, "Field index": fieldIndex, "Value": value])
    }
    /// Error raised when the encoding operation finishes, but there are still values in the buffer.
    static func _corruptedBuffer() -> CSVError<CSVEncoder> {
        .init(.bufferFailure,
              reason: "The encoding operation finished, but there were still values in the encoding buffer.",
              help: "This should never happen, please contact the repo maintainer sending data with a way to replicate this error.")
    }
    /// Error raised when the provided coding key couldn't be mapped into a concrete index since there is no CSV header.
    /// - parameter key: The key that was getting matched.
    /// - parameter codingPath: The full chain of containers which generated this error.
    static func _emptyHeader(forKey key: CodingKey, codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidConfiguration,
              reason: "The provided coding key identifying a field cannot be matched to a header, since the CSV file has no headers.",
              help: "Make the key generate an integer value or provide header during configuration.",
              userInfo: ["Coding path": codingPath, "Key": key])
    }
    /// Error raised when a record is fetched, but there are header names which has the same hash value (i.e. they have the same name).
    static func _invalidHashableHeader() -> CSVError<CSVEncoder> {
        .init(.invalidConfiguration,
              reason: "The header row contain two fields with the same value.",
              help: "Request a row instead of a record.")
    }
    /// Error raised when the provided coding key couldn't be mapped into a concrete index since it didn't match any header field.
    /// - parameter key: The key that was getting matched.
    /// - parameter codingPath: The full chain of containers which generated this error.
    static func _unmatchedHeader(forKey key: CodingKey, codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidConfiguration,
              reason: "The provided coding key identifying a field didn't match any CSV header.",
              help: "Make the key generate an integer value or provide a matching header.",
              userInfo: ["Coding path": codingPath, "Key": key])
    }
}
