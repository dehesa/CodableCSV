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
    /// The number of fields expected per row.
    var numExpectedFields: Int {
        //#warning("TODO")  // Used in unkeyed & single value containers
        fatalError()
    }
    
    /// Returns the number of rows that have been sent to this *sink*.
    ///
    /// The rows might not yet be fully encoded (i.e. written in their binary format).
    var numEncodedRows: Int {
        //#warning("TODO")  // Used in unkeyed container
        fatalError()
    }
    
    /// Returns the number of fields within the given row, which have been sent to this *sink*.
    ///
    /// The fields might not yet be fully encoded (i.e. written in their binary format).
    func numEncodedFields(at rowIndex: Int) -> Int {
        //#warning("TODO")  // Used in unkeyed container
        fatalError()
    }
    
    /// Returns the field index for the given coding key.
    ///
    /// This function first tries to extract the integer value from the key and if unavailable, the string value is extracted and matched against the CSV headers.
    /// - parameter key: The coding key representing the field's position within a row, or the field's name within the headers row.
    /// - returns: The position of the field within the row.
    func fieldIndex(forKey key: CodingKey, codingPath: [CodingKey]) throws -> Int {
        //#warning("TODO")  // Used in single value container
        fatalError()
    }
    
    /// Encodes the given field in the given position.
    func field(value: String, at rowIndex: Int, _ fieldIndex: Int) throws {
        //#warning("TODO")  // Used in single value container
        fatalError()
    }
}

//#warning("Strategy")
// No need for .ordered strategy since encoding only allow a row/field to be encoded once,
// but we may give the user the option to write empty rows as soon as a row jump happens.
