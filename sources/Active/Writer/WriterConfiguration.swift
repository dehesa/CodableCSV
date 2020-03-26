extension CSVWriter {
    /// Configuration for how to write CSV data.
    public struct Configuration {
        /// The field and row delimiters.
        public var delimiters: Delimiter.Pair
        /// The strategy to allow/disable escaped fields and how.
        public var escapingStrategy: Strategy.Escaping
        /// The row of headers to write at the beginning of the CSV data.
        ///
        /// If empty, no row will be written.
        public var headers: [String]
        /// The encoding used to serialize the CSV information.
        ///
        /// If no encoding is provided, UTF8 is presumed unless the CSV writer points to a file, in which case that file encoding will be used.
        public var encoding: String.Encoding?
        /// Indicates whether a [Byte Order Mark](https://en.wikipedia.org/wiki/Byte_order_mark) will be included at the beginning of the CSV representation.
        ///
        /// The BOM indicates the string encoding used for the CSV representation. If any, they always are the first bytes on a file.
        public var bomStrategy: Strategy.BOM

        /// Designated initlaizer setting the default values.
        public init() {
            self.delimiters = (field: ",", row: "\n")
            self.escapingStrategy = .doubleQuote
            self.headers = .init()
            self.encoding = nil
            self.bomStrategy = .convention
        }
    }
}

extension Strategy {
    /// Indicates whether the [Byte Order Mark](https://en.wikipedia.org/wiki/Byte_order_mark) will be serialize with the date or not.
    public enum BOM {
        /// Includes the optional BOM at the beginning of the CSV representation for a small number of encodings.
        ///
        /// A BOM will only be included for the following cases (as specified in the standard):
        /// - `.utf16` and `.unicode`, in which case the BOM for UTF 16 Big endian encoding will be used.
        /// - `.utf32` in which ase the BOM for UTF 32 Big endian encoding will be used.
        /// - For any other case, no BOM will be written.
        case convention
        /// Always writes a BOM when possible (i.e. for Unicode encodings).
        case always
        /// Never writes a BOM.
        case never
    }
}

// MARK: -

extension CSVWriter {
    /// Private configuration variables for the CSV writer.
    internal struct Settings {
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
                throw Error.invalidEmptyDelimiter()
            } else if field.elementsEqual(row) {
                throw Error.invalidDelimiters(field)
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

fileprivate extension CSVWriter.Error {
    /// Error raised when the the field or/and row delimiters are empty.
    /// - parameter delimiter: The indicated field and row delimiters.
    static func invalidEmptyDelimiter() -> CSVError<CSVWriter> {
        .init(.invalidConfiguration,
              reason: "The delimiters cannot be empty.",
              help: "Set delimiters that at least contain a unicode scalar/character.")
    }
    
    /// Error raised when the field and row delimiters are the same.
    /// - parameter delimiter: The indicated field and row delimiters.
    static func invalidDelimiters(_ delimiter: String.UnicodeScalarView) -> CSVError<CSVWriter> {
        .init(.invalidConfiguration,
              reason: "The field and row delimiters cannot be the same.",
              help: "Set different delimiters for field and rows.",
              userInfo: ["Delimiter": delimiter])
    }
}
