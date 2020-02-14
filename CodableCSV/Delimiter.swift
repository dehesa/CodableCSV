import Foundation

/// Separators scalars/strings.
public enum Delimiter {
    /// The delimiter between fields/vlaues.
    public enum Field: StringRepresentable {
        /// The unicode *comma* scalar (i.e. ",")
        case comma
        /// The unicode *semicolon* scalar (i.e. ";")
        case semicolon
        /// The unicode *tab* scalar (i.e. "\t").
        case tab
        /// A custom field delimiter composed from one or many Unicode scalars.
        case string(String)
        /// The field delimiter is not know before parsing the file. Try to infer it!
        case unknown
        
        public var stringValue: String? {
            switch self {
            case .comma: return ","
            case .semicolon: return ";"
            case .tab: return "\t"
            case .unknown: return nil
            case .string(let delimiter): return delimiter
            }
        }
    }
    
    /// The separator to use between rows.
    public enum Row: StringRepresentable {
        /// The unicode *linefeed* scalar (i.e. "\n")
        case lineFeed
        /// The unicode *carriage return* scalar (i.e. "\r")
        case carriageReturn
        /// The unicode sequence "\r\n"
        case carriageReturnLineFeed
        /// A custom row delimiter composed from one or many Unicode scalars.
        case string(String)
        /// The row delimiter is not know before parsing the file. Try to infer it!
        case unknown
        
        public var stringValue: String? {
            switch self {
            case .lineFeed: return "\n"
            case .carriageReturn: return "\r"
            case .carriageReturnLineFeed: return "\r\n"
            case .unknown: return nil
            case .string(let delimiter): return delimiter
            }
        }
    }
}

extension Delimiter {
    /// The CSV pair of delimiters (field & row delimiters).
    public typealias Pair = (field: Field, row: Row)
    /// The CSV pair of delimiter in string format.
    internal typealias RawPair = (field: String.UnicodeScalarView, row: String.UnicodeScalarView)
}
