import Foundation

extension ShadowDecoder {
    /// Source of all CSV rows.
    internal final class Source {
        /// The instance reading the CSV data.
        private let reader: CSVReader
        /// The row/field to be fetched next.
//        private(set) var nextIndex: (row: Int, field: Int)
        
        /// The decoding configuration.
        let configuration: CSVDecoder.Configuration
        /// The header record with the field names.
        var headers: [String]? { self.reader.headers }
        
        /// Designated initializer starting a CSV parsing process.
        /// - parameter data: The data blob containing the CSV information.
        /// - parameter encoding: String encoding used to transform the data blob into text.
        /// - parameter configuration: Generic CSV configuration to parse the data blob.
        init(data: Data, encoding: String.Encoding, configuration: CSVDecoder.Configuration) throws {
            do {
                self.configuration = configuration
                self.reader = try CSVReader(data: data, encoding: encoding, configuration: configuration.readerConfiguration)
            } catch let error {
                throw DecodingError.dataCorrupted(.init(codingPath: [],
                    debugDescription: "CSV reader/parser couldn't be initialized.",
                    underlyingError: error))
            }
//            self.nextIndex = (0, 0)
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
        #warning("Maybe parse the whole thing if someone request this property")
        return self.reader.rowIndex
    }
    
    /// Boolean indicating whether the given row index is out of bounds (i.e. there are no more elements left to be decoded in the file).
    /// - parameter index: The row index being checked.
    func isRowAtEnd(index: Int) -> Bool {
        let nextIndex = self.reader.rowIndex
        if index < nextIndex {
            return false
        } else if index == nextIndex {
            guard case .reading = self.reader.status else { return true }
            return false
        } else {
            fatalError("An index greater than the 'next row index' shall never be requested")
        }
    }
    
    /// Boolean indicating whether the row index is within the CSV file.
    func contains(rowIndex: Int) -> Bool {
        guard rowIndex >= 0 else { return false }
        #warning("TODO:")
        fatalError()
    }
}

extension ShadowDecoder.Source {
    /// Returns the number of fields that there is per record.
    var numFields: Int {
        #warning("TODO:")
        fatalError()
//        let (numRows, numFields) = self.reader.count
//        guard numRows > 0 else { return nil }
//        return numFields
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
                debugDescription: "The provided coding key identifying a field cannot be matched to a header, since the CSV file has no headers"))
        }
        //#warning("TODO: Very slow for large CSV headers")
        guard let result = headers.firstIndex(where: { $0 == name }) else {
            throw DecodingError.keyNotFound(key, .init(
                codingPath: codingPath,
                debugDescription: "The provided coding key identifying a field didn't match any CSV header"))
        }
        return result
    }
    
    func field(at rowIndex: Int, _ fieldIndex: Int) throws -> String {
        #warning("TODO:")
        fatalError()
    }
}
