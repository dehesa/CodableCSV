import Foundation

extension CSVReader {
    /// Configuration for how to read CSV data.
    public struct Configuration {
        /// The encoding used to identify the underlying data or `nil` if you want the CSV reader to try to figure it out.
        ///
        /// If no encoding is provided and the input data doesn't contain a Byte Order Marker (BOM), UTF8 is presumed.
        public var encoding: String.Encoding?
        /// The field and row delimiters.
        public var delimiters: Delimiter.Pair
        /// Indication on whether the CSV will contain a header row or not, or that information is unknown and it should try to be inferred.
        public var headerStrategy: Strategy.Header
        /// Trims the given characters at the beginning and end of each row, and between fields.
        public var trimStrategry: CharacterSet
        /// Boolean indicating whether the data/file/string should be completely parsed at reader's initialization.
        ///
        /// Setting this property to `true` samples the data/file/string at initialization time. This process returns some interesting data such as blob/file size, full-file encoding validation, etc.
        /// The *presample* process will however hurt performance since it iterates over all the data in initialization.
        public var presample: Bool
        
        /// Designated initializer setting the default values.
        public init() {
            self.encoding = nil
            self.delimiters = (field: ",", row: "\n")
            self.headerStrategy = .none
            self.trimStrategry = .init()
            self.presample = false
        }
    }
}

extension CSVReader {
    /// Private configuration variables for the CSV reader.
    internal struct Settings {
        /// The unicode scalar delimiters for fields and rows.
        let delimiters: Delimiter.RawPair
        /// The characters set to be trimmed at the beginning and ending of each field.
        let trimCharacters: CharacterSet
        /// The unicode scalar used as encapsulator and escaping character (when printed two times).
        let escapingScalar: Unicode.Scalar = "\""
        
        /// Creates the inmutable reader settings from the user provided configuration values.
        /// - parameter configuration: The configuration values provided by the API user.
        /// - parameter iterator: The iterator providing `Unicode.Scalar` values.
        /// - parameter buffer: Small buffer use to store `Unicode.Scalar` values that have been read from the input, but haven't yet been processed.
        init(configuration: Configuration, iterator: ScalarIterator, buffer: ScalarBuffer) throws {
            // 1. Figure out the field and row delimiters.
            switch (configuration.delimiters.field.rawValue, configuration.delimiters.row.rawValue) {
            case (nil, nil):
                self.delimiters = try CSVReader.inferDelimiters(iterator: iterator, buffer: buffer)
            case (nil, let row):
                self.delimiters = try CSVReader.inferFieldDelimiter(rowDelimiter: row, iterator: iterator, buffer: buffer)
            case (let field, nil):
                self.delimiters = try CSVReader.inferRowDelimiter(fieldDelimiter: field, iterator: iterator, buffer: buffer)
            case (let field, let row) where !field.elementsEqual(row):
                self.delimiters = (field, row)
            case (let delimiter, _):
                throw CSVReader.Error.invalidDelimiters(delimiter)
            }
            // 2. Set the trim characters set.
            self.trimCharacters = configuration.trimStrategry
        }
    }
}

fileprivate extension CSVReader.Error {
    /// Error raised when the field and row delimiters are the same.
    /// - parameter delimiter: The indicated field and row delimiters.
    static func invalidDelimiters(_ delimiter: String.UnicodeScalarView) -> CSVReader.Error {
        .init(.invalidDelimiter,
              reason: "The field and row delimiters cannot be the same.",
              help: "Set different delimiters for field and rows.",
              userInfo: ["Delimiter": delimiter])
    }
}
