import Foundation

extension CSVReader {
    /// Configuration for how to read CSV data.
    public struct Configuration {
        /// The field and row delimiters.
        public var delimiters: Delimiter.Pair
        /// Indication on whether the CSV will contain a header row or not, or that information is unknown and it should try to be inferred.
        public var headerStrategy: Strategy.Header
        /// Trims the given characters at the beginning and end of each row, and between fields.
        public var trimStrategry: CharacterSet
        /// The strategy for escaping quoted fields.
        public var escapingStrategy: Strategy.Escaping
        /// The encoding used to identify the underlying data or `nil` if you want the CSV reader to try to figure it out.
        ///
        /// If no encoding is provided and the input data doesn't contain a Byte Order Marker (BOM), UTF8 is presumed.
        public var encoding: String.Encoding?
        /// Boolean indicating whether the data/file/string should be completely parsed at reader's initialization.
        ///
        /// Setting this property to `true` samples the data/file/string at initialization time. This process returns some interesting data such as blob/file size, full-file encoding validation, etc.
        /// The *presample* process will however hurt performance since it iterates over all the data in initialization.
        public var presample: Bool
        
        /// Designated initializer setting the default values.
        public init() {
            self.delimiters = (field: ",", row: "\n")
            self.headerStrategy = .none
            self.trimStrategry = .init()
            self.escapingStrategy = .doubleQuote
            self.encoding = nil
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
        let escapingScalar: Unicode.Scalar?
        
        /// Creates the inmutable reader settings from the user provided configuration values.
        /// - parameter configuration: The configuration values provided by the API user.
        /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
        /// - parameter buffer: Small buffer use to store `Unicode.Scalar` values that have been read from the input, but haven't yet been processed.
        /// - throws: `CSVError<CSVReader>` exclusively.
        init(configuration: Configuration, decoder: ScalarDecoder, buffer: ScalarBuffer) throws {
            // 1. Figure out the field and row delimiters.
            switch (configuration.delimiters.field.rawValue, configuration.delimiters.row.rawValue) {
            case (nil, nil):
                self.delimiters = try CSVReader.inferDelimiters(decoder: decoder, buffer: buffer)
            case (nil, let row):
                self.delimiters = try CSVReader.inferFieldDelimiter(rowDelimiter: row, decoder: decoder, buffer: buffer)
            case (let field, nil):
                self.delimiters = try CSVReader.inferRowDelimiter(fieldDelimiter: field, decoder: decoder, buffer: buffer)
            case (let field, let row) where !field.elementsEqual(row):
                self.delimiters = (.init(field), .init(row))
            case (let delimiter, _):
                throw Error.invalidDelimiters(delimiter)
            }
            // 2. Set the trim characters set.
            self.trimCharacters = configuration.trimStrategry
            // 3. Set the escaping scalar.
            self.escapingScalar = configuration.escapingStrategy.scalar
            // 4. Ensure trim character set does not include escaping scalar
            if let escapingScalar = escapingScalar, trimCharacters.contains(escapingScalar) {
                throw Error.invalidTrimCharacter(escapingScalar: escapingScalar, trimCharacters: trimCharacters)
            }
        }
    }
}

fileprivate extension CSVReader.Error {
    /// Error raised when the field and row delimiters are the same.
    /// - parameter delimiter: The indicated field and row delimiters.
    static func invalidDelimiters(_ delimiter: String.UnicodeScalarView) -> CSVError<CSVReader> {
        .init(.invalidConfiguration,
              reason: "The field and row delimiters cannot be the same.",
              help: "Set different delimiters for field and rows.",
              userInfo: ["Delimiter": delimiter])
    }

    static func invalidTrimCharacter(escapingScalar: Unicode.Scalar, trimCharacters: CharacterSet) -> CSVError<CSVReader> {
        .init(.invalidConfiguration,
              reason: "The trim characters set can not include the escaping scalar.",
              help: "Remove the escaping scalar from the trim characters set.",
              userInfo: ["Escaping scalar": escapingScalar, "Trim characters": trimCharacters])
    }
}
