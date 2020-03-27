extension ShadowEncoder {
    /// Sink of all CSV data.
    internal final class Sink {
        /// The instance writing the CSV data.
        private let writer: CSVWriter
        /// The decoding configuration.
        let configuration: CSVEncoder.Configuration
        /// Any contextual information set by the user for decoding.
        let userInfo: [CodingUserInfoKey:Any]
        
        /// Creates the unique data sink for the encoding process.
        init(writer: CSVWriter, configuration: CSVEncoder.Configuration, userInfo: [CodingUserInfoKey:Any]) {
            self.writer = writer
            self.configuration = configuration
            self.userInfo = userInfo
        }
    }
}

extension ShadowEncoder.Sink {
    /// Returns the field index for the given coding key.
    ///
    /// This function first tries to extract the integer value from the key and if unavailable, the string value is extracted and matched against the CSV headers.
    /// - parameter key: The coding key representing the field's position within a row, or the field's name within the headers row.
    /// - throws: `DecodingError` exclusively.
    /// - returns: The position of the field within the row.
    func fieldIndex(forKey key: CodingKey, codingPath: [CodingKey]) throws -> Int {
        #warning("TODO:")
        fatalError()
    }
    
    /// Encodes the given field in the given position.
    func field(value: String, at rowIndex: Int, _ fieldIndex: Int) throws {
        #warning("TODO: Sink field(value:at:_:)")
        fatalError()
    }
}

#warning("Strategy")
// No need for .ordered strategy since encoding only allow a row/field to be encoded once,
// but we may give the user the option to write empty rows as soon as a row jump happens.
