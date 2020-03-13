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
        /// The header record with the field names.
        var headers: [String]? { self.reader.headers }
        /// Any contextual information set by the user for decoding.
        let userInfo: [CodingUserInfoKey:Any]
        
        /// Designated initializer starting a CSV parsing process.
        /// - parameter data: The data blob containing the CSV information.
        /// - parameter encoding: String encoding used to transform the data blob into text.
        /// - parameter configuration: Generic CSV configuration to parse the data blob.
        /// - parameter userInfo: Any contextual information set by the user for decoding.
        init(data: Data, encoding: String.Encoding, configuration: CSVDecoder.Configuration, userInfo: [CodingUserInfoKey:Any]) throws {
            self.configuration = configuration
            var readerConfiguration = configuration.readerConfiguration
            readerConfiguration.encoding = encoding
            self.reader = try CSVReader(data: data, configuration: readerConfiguration)
            self.buffer = Buffer(strategy: configuration.bufferingStrategy)
            self.userInfo = userInfo
        }
    }
}

extension ShadowDecoder.Source {
    /// Number of rows within the CSV file.
    ///
    /// It is unknown till all the rows have been read.
    var numRows: Int? {
        switch self.reader.status {
        case .finished, .failed: break
        case .reading: return nil
        }
        return self.reader.rowIndex
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
    /// - returns: The position of the field within the row.
    func fieldIndex(forKey key: CodingKey, codingPath: [CodingKey]) throws -> Int {
        if let index = key.intValue { return index }
        
        let name = key.stringValue
        guard let headers = self.headers else {
            throw DecodingError.keyNotFound(key, .init(
                codingPath: codingPath,
                debugDescription: "The provided coding key identifying a field cannot be matched to a header, since the CSV file has no headers."))
        }
        //#warning("TODO: Very slow for large CSV headers")
        guard let result = headers.firstIndex(where: { $0 == name }) else {
            throw DecodingError.keyNotFound(key, .init(
                codingPath: codingPath,
                debugDescription: "The provided coding key identifying a field didn't match any CSV header."))
        }
        return result
    }
    
    /// Returns the field value in the given `rowIndex` row at the given `fieldIndex` position.
    func field(at rowIndex: Int, _ fieldIndex: Int) throws -> String {
        var nextIndex = self.reader.rowIndex
        /// If the row has been parsed previously, retrieve it from the buffer.
        guard rowIndex >= nextIndex else {
            guard let row = self.buffer.retrieve(at: rowIndex) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: [DecodingKey(rowIndex), DecodingKey(fieldIndex)],
                    debugDescription: "A previously decoded row has been discarded. Change the decoder's buffering strategy and try again."))
            }
            return row[fieldIndex]
        }
        
        var result: [String]? = nil
        var counter = rowIndex - (nextIndex - 1)
        
        while counter > 0 {
            guard let row = try self.reader.parseRow() else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: [DecodingKey(nextIndex)],
                    debugDescription: "The reader reached the end of the CSV file (num rows: \(nextIndex)). Therefore the requested row at position '\(rowIndex)' didn't exist."))
            }
            self.buffer.store(row, at: nextIndex)
            nextIndex += 1
            counter -= 1
            result = row
        }
        
        guard let row = result else { fatalError() }
        guard row.count > fieldIndex else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: [DecodingKey(rowIndex), DecodingKey(fieldIndex)],
                debugDescription: "The provided field index is out of bounds."))
        }
        return row[fieldIndex]
    }
}
