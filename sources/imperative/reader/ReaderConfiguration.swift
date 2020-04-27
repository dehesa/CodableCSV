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
        /// The strategy to allow/disable escaped fields and how.
        public var escapingStrategy: Strategy.Escaping
        /// Indication on whether the CSV will contain a header row or not, or that information is unknown and it should try to be inferred.
        public var headerStrategy: Strategy.Header
        /// Trims the given characters at the beginning and end of each row, and between fields.
        public var trimStrategry: CharacterSet
        /// Boolean indicating whether the data/file/string should be completely parsed at reader's initialization.
        ///
        /// Setting this property to `true` samples the data/file/string at initialization time. This process returns some interesting data such as blob/file size, full-file encoding validation, etc.
        /// The _presample_ process will however hurt performance since it iterates over all the data in initialization.
        public var presample: Bool
        
        /// Designated initializer setting the default values.
        public init() {
            self.encoding = nil
            self.delimiters = (field: ",", row: "\n")
            self.escapingStrategy = .doubleQuote
            self.headerStrategy = .none
            self.trimStrategry = .init()
            self.presample = false
        }
    }
}

// MARK: -

extension Strategy {
    /// Indication on whether the CSV file contains headers or not.
    public enum Header: ExpressibleByNilLiteral, ExpressibleByBooleanLiteral {
        /// The CSV contains no header row.
        case none
        /// The CSV contains a single header row.
        case firstLine
//        /// It is not known whether the CSV contains a header row. The library will try to infer it!
//        case unknown
        
        public init(nilLiteral: ()) {
            self = .none
        }
        
        public init(booleanLiteral value: BooleanLiteralType) {
            self = (value) ? .firstLine : .none
        }
    }
}
