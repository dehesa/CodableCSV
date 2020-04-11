extension ShadowDecoder {
    /// Source of all CSV rows.
    internal final class Source {
        /// The instance reading the CSV data.
        private let _reader: CSVReader
        /// The rows buffer.
        private let _buffer: Buffer
        /// The decoding configuration.
        let configuration: CSVDecoder.Configuration
        /// Any contextual information set by the user for decoding.
        let userInfo: [CodingUserInfoKey:Any]
        /// The header row with the field names.
        let headers: [String]
        /// Lookup dictionary providing fast index discovery for header names.
        private var _headerLookup: [Int:Int]
        /// Returns the field value in the given `rowIndex` row at the given `fieldIndex` position.
        let field: (_ rowIndex: Int, _ fieldIndex: Int) throws -> String
        
        /// Creates the unique data source for a decoding process.
        /// - parameter reader: The instance actually reading the input bytes.
        /// - parameter configuration: Generic CSV configuration to parse the data blob.
        /// - parameter userInfo: Any contextual information set by the user for decoding.
        init(reader: CSVReader, configuration: CSVDecoder.Configuration, userInfo: [CodingUserInfoKey:Any]) {
            self._reader = reader
            self._buffer = Buffer(strategy: configuration.bufferingStrategy)
            self.configuration = configuration
            self.userInfo = userInfo
            self.headers = reader.headers
            self._headerLookup = .init()
            
            switch configuration.bufferingStrategy {
            case .keepAll:
                self.field = { [unowned buffer = self._buffer, unowned reader = self._reader] in
                    var result: [String]
                    var nextIndex = reader.rowIndex
                    // A.1. Has the requested row already been parsed?
                    if $0 < nextIndex {
                        // A.1.1. If so, retrieve it from the buffer.
                        result = try buffer.fetch(at: $0) ?! DecodingError._corruptedBuffer(rowIndex: $0, fieldIndex: $1)
                    } else {
                        // A.1.2. Otherwise, read all necessary rows from the input
                        repeat {
                            result = try reader.readRow() ?! DecodingError._rowOutOfBounds(rowIndex: $0, rowCount: nextIndex)
                            buffer.store(result, at: nextIndex)
                            nextIndex += 1
                        } while $0 > nextIndex
                    }
                    // A.2. Check that the requested fields is not out of bounds.
                    guard result.count > $1 else { throw DecodingError._fieldOutOfBounds(rowIndex: $0, fieldIndex: $1, fieldCount: result.count) }
                    return result[$1]
                }
                
//            case .unrequested:
//                self.field = { [unowned buffer = self.buffer, unowned reader = self.reader] in
//                    // #warning("TODO: unrequested strategy")
//                }
                
            case .sequential:
                self.field = { [unowned buffer = self._buffer, unowned reader = self._reader] in
                    var result: [String]
                    var nextIndex = reader.rowIndex
                    // C.1. Is the requested row in the buffer? (only the row right before the writer's pointer shall be in the buffer).
                    if $0 == nextIndex-1 {
                        result = try buffer.fetch(at: $0) ?! DecodingError._expiredCache(rowIndex: $0, fieldIndex: $1)
                    // C.2. Is the user trying to query a previously decoded row?
                    } else if $0 < nextIndex-1 {
                        throw DecodingError._expiredCache(rowIndex: $0, fieldIndex: $1)
                    // C.3. Is the row further along?
                    } else {
                        // C.3.1. The sequential strategy doesn't require any buffering.
                        buffer.removeAll()
                        // C.3.2. Reach the required row.
                        repeat {
                            result = try reader.readRow() ?! DecodingError._rowOutOfBounds(rowIndex: $0, rowCount: nextIndex)
                            nextIndex += 1
                        } while $0 > nextIndex
                        
                        buffer.store(result, at: nextIndex-1)
                    }
                    
                    // C.4. Check that the requested field is not out of bounds.
                    guard result.count > $1 else { throw DecodingError._fieldOutOfBounds(rowIndex: $0, fieldIndex: $1, fieldCount: result.count) }
                    return result[$1]
                }
            }
        }
    }
}

extension ShadowDecoder.Source {
    /// Number of rows within the CSV file.
    ///
    /// It is unknown till all the rows have been read.
    var numRows: Int? {
        switch self._reader.status {
        case .finished, .failed: return self._reader.rowIndex
        case .active: return nil
        }
    }
    
    /// Boolean indicating whether the given row index is out of bounds (i.e. there are no more elements left to be decoded in the file).
    /// - parameter index: The row index being checked.
    func isRowAtEnd(index: Int) -> Bool {
        var nextIndex = self._reader.rowIndex
        guard index >= nextIndex else { return false }
        
        var counter = index - (nextIndex - 1)
        while counter > 0 {
            guard let row = try? self._reader.readRow() else { return true }
            self._buffer.store(row, at: nextIndex)
            nextIndex += 1
            counter -= 1
        }
        
        guard case .active = self._reader.status else { return true }
        return false
    }
    
    /// Boolean indicating whether the row index points to a valid CSV row.
    /// - parameter rowIndex: The index indicating a row position within the CSV file.
    func contains(rowIndex: Int) -> Bool {
        guard rowIndex >= 0 else { return false }
        
        var nextIndex = self._reader.rowIndex
        var counter = rowIndex - (nextIndex - 1)
        while counter > 0 {
            guard let row = try? self._reader.readRow() else { return false }
            self._buffer.store(row, at: nextIndex)
            nextIndex += 1
            counter -= 1
        }
        
        return true
    }
}

extension ShadowDecoder.Source {
    /// Returns the number of fields that there is per row.
    ///
    /// If the number is not know at call time, a row is decoded to figure out how many fields there are.
    var numExpectedFields: Int {
        let (numRows, numFields) = self._reader.count
        guard numRows <= 0 else { return numFields }
        
        guard let row = try? self._reader.readRow() else { return 0 }
        self._buffer.store(row, at: 0)
        return row.count
    }
    
    /// Boolean indicating whether the given field index is out of bounds (i.e. there are no more elements left to be decoded in the row).
    /// - parameter index: The field index being checked.
    func isFieldAtEnd(index: Int) -> Bool {
        return index >= self.numExpectedFields
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
        if self._headerLookup.isEmpty {
            guard !self.headers.isEmpty else { throw DecodingError._emptyHeader(key: key, codingPath: codingPath) }
            self._headerLookup = try self.headers.lookupDictionary(onCollision: { DecodingError._invalidHashableHeader(codingPath: codingPath) })
        }
        
        return try self._headerLookup[name.hashValue] ?! DecodingError._unmatchedHeader(forKey: key, codingPath: codingPath)
    }
}

fileprivate extension DecodingError {
    /// Error raised when a record is fetched, but there are header names which has the same hash value (i.e. they have the same name).
    static func _invalidHashableHeader(codingPath: [CodingKey]) -> DecodingError {
        DecodingError.dataCorrupted(
            Context(codingPath: codingPath,
                    debugDescription: "The header row contain two fields with the same value.")
        )
    }
    /// The provided coding key couldn't be mapped into a concrete index since there is no CSV header.
    static func _emptyHeader(key: CodingKey, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.keyNotFound(key, .init(codingPath: codingPath,
            debugDescription: "The provided coding key identifying a field cannot be matched to a header, since the CSV file has no headers."))
    }
    /// The provided coding key couldn't be mapped into a concrete index since it didn't match any header field.
    static func _unmatchedHeader(forKey key: CodingKey, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.keyNotFound(key, .init(codingPath: codingPath,
            debugDescription: "The provided coding key identifying a field didn't match any CSV header."))
    }
    /// Error raised when a previously decoded row is asked to the buffer and the buffer doesn't have it, although the strategy force the buffer to keep all the values.
    static func _corruptedBuffer(rowIndex: Int, fieldIndex: Int) -> DecodingError {
        DecodingError.valueNotFound(String.self, .init(codingPath: [IndexKey(rowIndex), IndexKey(fieldIndex)],
            debugDescription: "A previously decoded row hasn't been found in the cache. Please contact the repo maintainer."))
    }
    /// Error raised when the user asks again for a previously decoded row that has been discarded.
    ///
    /// If the buffer strategy is too restrictive, the previosly decoded rows are being discarded.
    static func _expiredCache(rowIndex: Int, fieldIndex: Int) -> DecodingError {
        let fieldKey = IndexKey(fieldIndex)
        return DecodingError.keyNotFound(fieldKey, .init(codingPath: [IndexKey(rowIndex), fieldKey],
            debugDescription: "A previously decoded row has been discarded. Change the decoder's buffering strategy and try again."))
    }
    /// Error raised when a row is queried, which is outside the CSV number of rows.
    static func _rowOutOfBounds(rowIndex: Int, rowCount: Int) -> DecodingError {
        let rowKey = IndexKey(rowIndex)
        return DecodingError.keyNotFound(rowKey, .init(codingPath: [rowKey],
            debugDescription: "The reader reached the end of the CSV file (num rows: \(rowCount)). Therefore the requested row at position '\(rowIndex)' didn't exist."))
    }
    /// Error raised when a given field index is out of bounds.
    static func _fieldOutOfBounds(rowIndex: Int, fieldIndex: Int, fieldCount: Int) -> DecodingError {
        let fieldKey = IndexKey(fieldIndex)
        return DecodingError.keyNotFound(fieldKey, .init(codingPath: [IndexKey(rowIndex), fieldKey],
            debugDescription: "The provided field index is out of bounds."))
    }
}
