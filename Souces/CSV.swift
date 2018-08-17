import Foundation

/// Wrapper around CSV properties.
public enum CSV {
    /// Separators scalars/strings.
    public enum Delimiter {
        /// The delimiter between fields/vlaues.
        public enum Field {
            /// The unicode *comma* scalar (i.e. ",")
            case comma
            /// The unicode *semicolon* scalar (i.e. ";")
            case semicolon
            /// The unicode *tab* scalar (i.e. "\t").
            case tab
            /// A custom field delimiter composed from one to many Unicode scalars.
            case string(String)
            /// The field delimiter is not know before parsing the file. Try to infer it!
            case unknown
        }
        
        /// The separator to use between rows.
        public enum Row {
            /// The unicode *linefeed* scalar (i.e. "\n")
            case lineFeed
            /// The unicode *carriage return* scalar (i.e. "\r")
            case carriageReturn
            /// The unicode sequence "\r\n"
            case carriageReturnLineFeed
            /// A custom row delimiter composed from one to many Unicode scalars.
            case string(String)
            /// The row delimiter is not know before parsing the file. Try to infer it!
            case unknown
        }
        
        /// The CSV pair of delimiters (field & row delimiters).
        public typealias Pair = (field: Field, row: Row)
        /// The CSV pair of delimiter in string format.
        internal typealias RawPair = (field: String.UnicodeScalarView, row: String.UnicodeScalarView)
    }
    
    /// The strategies to use when encoding/decoding.
    public enum Strategy {
        /// Indication on whether the CSV file contains headers or not.
        public enum Header: ExpressibleByNilLiteral {
            /// The CSV contains no header row.
            case none
            /// The CSV contains a single header row.
            case firstLine
            /// It is not known whether the CSV contains a header row. Try to infer it!
            case unknown
            
            public init(nilLiteral: ()) { self = .none }
        }
        
        /// Indication on whether some character set should be trimmed or not at the beginning and ending of a CSV field.
        public enum Trim: ExpressibleByNilLiteral {
            /// No characters will be trimmed from the input/output.
            case none
            /// White spaces before and after delimiters will be trimmed.
            case whitespaces
            /// The given set of characters will be trimmed before and after delimiters.
            case set(CharacterSet)
            
            public init(nilLiteral: ()) { self = .none }
        }
    }
}

extension CSV {
    /// Configuration for how to parse CSV data.
    public struct Configuration {
        /// The field and row delimiters.
        ///
        /// By default, it is a comma for fields and a carriage return + line feed for a row.
        public var delimiters: CSV.Delimiter.Pair
        /// Indications on how to proceed with header data and field trimming.
        public var strategies: (header: CSV.Strategy.Header, trim: CSV.Strategy.Trim)
        
        /// General configurations for CSV codecs and parsers.
        /// - parameter headerStrategy: Whether the CSV data contains headers at the beginning of the file.
        /// - parameter trimStrategy: Whether some characters in a set should be trim at the beginning and ending of a CSV field.
        public init(fieldDelimiter: CSV.Delimiter.Field = .comma, rowDelimiter: CSV.Delimiter.Row = .lineFeed, headerStrategy: CSV.Strategy.Header = .none, trimStrategy: CSV.Strategy.Trim = .none) {
            self.delimiters = (fieldDelimiter, rowDelimiter)
            self.strategies = (headerStrategy, trimStrategy)
        }
    }
}

extension Unicode.Scalar {
    /// The quote unicode scalar used as escaping character.
    internal static let quote: Unicode.Scalar = "\""
}
