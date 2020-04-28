extension CSVWriter: Failable {
    /// The type of error raised by the CSV writer.
    public enum Error: Int {
        /// Some of the configuration values provided are invalid.
        case invalidConfiguration = 1
        /// The CSV data is invalid.
        case invalidInput = 2
        /// The output stream failed.
        case streamFailure = 4
        /// The operation couldn't be carried or failed midway.
        case invalidOperation = 5
    }
    
    public static var errorDomain: String {
        "Writer"
    }
    
    public static func errorDescription(for failure: Error) -> String {
        switch failure {
        case .invalidConfiguration: return "Invalid configuration"
        case .invalidInput: return "Invalid input"
        case .streamFailure: return "Stream failure"
        case .invalidOperation: return "Invalid operation"
        }
    }
}

internal extension CSVWriter {
    /// Private configuration variables for the CSV writer.
    struct Settings {
        /// The unicode scalar delimiters for fields and rows.
        let delimiters: Delimiter.RawPair
        /// The unicode scalar used as encapsulator and escaping character (when printed two times).
        let escapingScalar: Unicode.Scalar?
        /// Boolean indicating whether the received CSV contains a header row or not.
        let headers: [String]
        /// The encoding used to identify the underlying data.
        let encoding: String.Encoding
        
        /// Designated initializer taking generic CSV configuration (with possible unknown data) and making it specific to a CSV writer instance.
        /// - parameter configuration: The public CSV writer configuration variables.
        /// - throws: `CSVError<CSVWriter>` exclusively.
        init(configuration: CSVWriter.Configuration, encoding: String.Encoding) throws {
            // 1. Validate the delimiters.
            let (field, row) = (configuration.delimiters.field.rawValue, configuration.delimiters.row.rawValue)
            if field.isEmpty || row.isEmpty {
                throw Error._invalidEmptyDelimiter()
            } else if field.elementsEqual(row) {
                throw Error._invalidSameDelimiters(field)
            } else {
                self.delimiters = (.init(field), .init(row))
            }
            // 2. Copy all other values.
            self.escapingScalar = configuration.escapingStrategy.scalar
            self.headers = configuration.headers
            self.encoding = encoding
        }
    }
}

// MARK: -

fileprivate extension CSVWriter.Error {
    /// Error raised when the the field or/and row delimiters are empty.
    /// - parameter delimiter: The indicated field and row delimiters.
    static func _invalidEmptyDelimiter() -> CSVError<CSVWriter> {
        .init(.invalidConfiguration,
              reason: "The delimiters cannot be empty.",
              help: "Set delimiters that at least contain a unicode scalar/character.")
    }
    /// Error raised when the field and row delimiters are the same.
    /// - parameter delimiter: The indicated field and row delimiters.
    static func _invalidSameDelimiters(_ delimiter: String.UnicodeScalarView) -> CSVError<CSVWriter> {
        .init(.invalidConfiguration,
              reason: "The field and row delimiters cannot be the same.",
              help: "Set different delimiters for field and rows.",
              userInfo: ["Delimiter": delimiter])
    }
}

