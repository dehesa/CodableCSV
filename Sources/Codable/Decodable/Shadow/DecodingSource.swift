import Foundation

extension ShadowDecoder {
    /// Source of all CSV rows.
    internal final class Source {
        /// The instance reading the CSV data.
        private let reader: CSVReader
        /// The rows buffer.
        private let buffer: Buffer
        /// The decoding configuration.
        let configuration: CSVDecoder.Configuration
        /// Any contextual information set by the user for decoding.
        let userInfo: [CodingUserInfoKey:Any]
        /// The header record with the field names.
        let headers: [String]
        /// Lookup dictionary providing fast index discovery for header names.
        private let headerLookup: [Int:Int]
        
        /// Creates the unique data source for a decoding process.
        /// - parameter reader: The instance actually reading the input bytes.
        /// - parameter configuration: Generic CSV configuration to parse the data blob.
        /// - parameter userInfo: Any contextual information set by the user for decoding.
        init(reader: CSVReader, configuration: CSVDecoder.Configuration, userInfo: [CodingUserInfoKey:Any]) {
            self.reader = reader
            self.buffer = Buffer(strategy: configuration.bufferingStrategy)
            self.configuration = configuration
            self.userInfo = userInfo
            self.headers = reader.headers
            self.headerLookup = (self.headers.isEmpty) ? .init() : try! reader.makeHeaderLookup()
        }
    }
}

extension ShadowDecoder.Source {
    /// Number of rows within the CSV file.
    ///
    /// It is unknown till all the rows have been read.
    var numRows: Int? {
        switch self.reader.status {
        case .finished, .failed: return self.reader.rowIndex
        case .reading: return nil
        }
    }
    
    /// Boolean indicating whether the given row index is out of bounds (i.e. there are no more elements left to be decoded in the file).
    /// - parameter index: The row index being checked.
    func isRowAtEnd(index: Int) -> Bool {
        var nextIndex = self.reader.rowIndex
        guard index >= nextIndex else { return false }
        
        var counter = index - (nextIndex - 1)
        while counter > 0 {
            guard let row = try? self.reader.parseRow() else { return true }
            self.buffer.store(row, at: nextIndex)
            nextIndex += 1
            counter -= 1
        }
        
        guard case .reading = self.reader.status else { return true }
        return false
    }
    
    /// Boolean indicating whether the row index points to a valid CSV row.
    /// - parameter rowIndex: The index indicating a row position within the CSV file.
    func contains(rowIndex: Int) -> Bool {
        guard rowIndex >= 0 else { return false }
        
        var nextIndex = self.reader.rowIndex
        var counter = rowIndex - (nextIndex - 1)
        while counter > 0 {
            guard let row = try? self.reader.parseRow() else { return false }
            self.buffer.store(row, at: nextIndex)
            nextIndex += 1
            counter -= 1
        }
        
        return true
    }
}

extension ShadowDecoder.Source {
    /// Returns the number of fields that there is per record.
    var numFields: Int {
        let (numRows, numFields) = self.reader.count
        guard numRows <= 0 else { return numFields }
        
        guard let row = try? self.reader.parseRow() else { return 0 }
        self.buffer.store(row, at: 0)
        return row.count
    }
    
    /// Boolean indicating whether the given field index is out of bounds (i.e. there are no more elements left to be decoded in the row).
    /// - parameter index: The field index being checked.
    func isFieldAtEnd(index: Int) -> Bool {
        return index >= self.numFields
    }
    
    /// Returns the field index for the given coding key.
    ///
    /// This function first tries to extract the integer value from the key and if unavailable, the string value is extracted and matched against the CSV headers.
    /// - parameter key: The coding key representing the field's position within a row, or the field's name within the headers row.
    /// - throws: `DecodingError` exclusively.
    /// - returns: The position of the field within the row.
    func fieldIndex(forKey key: CodingKey, codingPath: [CodingKey]) throws -> Int {
        if let index = key.intValue { return index }
        
        let name = key.stringValue
        guard !self.headerLookup.isEmpty else { throw DecodingError.emptyHeader(key: key, codingPath: codingPath) }
        return try self.headerLookup[name.hashValue] ?! DecodingError.unmatchedHeader(forKey: key, codingPath: codingPath)
    }
    
    /// Returns the field value in the given `rowIndex` row at the given `fieldIndex` position.
    func field(at rowIndex: Int, _ fieldIndex: Int) throws -> String {
        var nextIndex = self.reader.rowIndex
        /// If the row has been parsed previously, retrieve it from the buffer.
        guard rowIndex >= nextIndex else {
            guard let row = self.buffer.retrieve(at: rowIndex) else {
                throw DecodingError.expiredCache(rowIndex: rowIndex, fieldIndex: fieldIndex)
            }
            return row[fieldIndex]
        }
        
        var result: [String]? = nil
        var counter = rowIndex - (nextIndex - 1)
        
        while counter > 0 {
            guard let row = try self.reader.parseRow() else {
                throw DecodingError.rowOutOfBounds(rowIndex: rowIndex, rowCount: nextIndex)
            }
            self.buffer.store(row, at: nextIndex)
            nextIndex += 1
            counter -= 1
            result = row
        }
        
        guard let row = result else { fatalError() }
        let numFields = row.count
        guard numFields > fieldIndex else {
            throw DecodingError.fieldOutOfBounds(rowIndex: rowIndex, fieldIndex: fieldIndex, fieldCount: numFields)
        }
        return row[fieldIndex]
    }
}

fileprivate extension DecodingError {
    /// The provided coding key couldn't be mapped into a concrete index since there is no CSV header.
    static func emptyHeader(key: CodingKey, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.keyNotFound(key, .init(codingPath: codingPath,
            debugDescription: "The provided coding key identifying a field cannot be matched to a header, since the CSV file has no headers."))
    }
    /// The provided coding key couldn't be mapped into a concrete index since it didn't match any header field.
    static func unmatchedHeader(forKey key: CodingKey, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.keyNotFound(key, .init(codingPath: codingPath,
            debugDescription: "The provided coding key identifying a field didn't match any CSV header."))
    }
    /// Error raised when the user asks again for a previously decoded row that has been discarded.
    ///
    /// If the buffer strategy is too restrictive, the previosly decoded rows are being discarded.
    static func expiredCache(rowIndex: Int, fieldIndex: Int) -> DecodingError {
        let fieldKey = DecodingKey(fieldIndex)
        return DecodingError.keyNotFound(fieldKey, .init(codingPath: [DecodingKey(rowIndex), fieldKey],
            debugDescription: "A previously decoded row has been discarded. Change the decoder's buffering strategy and try again."))
    }
    /// Error raised when a row is queried, which is outside the CSV number of rows.
    static func rowOutOfBounds(rowIndex: Int, rowCount: Int) -> DecodingError {
        let rowKey = DecodingKey(rowIndex)
        return DecodingError.keyNotFound(rowKey, .init(codingPath: [rowKey],
            debugDescription: "The reader reached the end of the CSV file (num rows: \(rowCount)). Therefore the requested row at position '\(rowIndex)' didn't exist."))
    }
    /// Error raised when
    static func fieldOutOfBounds(rowIndex: Int, fieldIndex: Int, fieldCount: Int) -> DecodingError {
        let fieldKey = DecodingKey(fieldIndex)
        return DecodingError.keyNotFound(fieldKey, .init(codingPath: [DecodingKey(rowIndex), fieldKey],
            debugDescription: "The provided field index is out of bounds."))
    }
}
