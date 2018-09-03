import Foundation

/// Wrapper around CSV properties.
extension Configuration {
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
            /// A custom field delimiter composed from one to many Unicode scalars.
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
            /// A custom row delimiter composed from one to many Unicode scalars.
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
        
        /// The CSV pair of delimiters (field & row delimiters).
        public typealias Pair = (field: Field, row: Row)
        /// The CSV pair of delimiter in string format.
        internal typealias RawPair = (field: String.UnicodeScalarView, row: String.UnicodeScalarView)
    }
}

extension Configuration {
    /// The strategies to use when encoding/decoding.
    public enum Strategy {
        /// Indication on whether the CSV file contains headers or not.
        public enum Header: ExpressibleByNilLiteral, ExpressibleByBooleanLiteral {
            /// The CSV contains no header row.
            case none
            /// The CSV contains a single header row.
            case firstLine
            /// It is not known whether the CSV contains a header row. Try to infer it!
            case unknown
            
            public init(nilLiteral: ()) { self = .none }
            
            public init(booleanLiteral value: BooleanLiteralType) {
                self = (value) ? .firstLine : .none
            }
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
        
        /// The strategy to use for non-standard floating-point values (IEEE 754 infinity and NaN).
        public enum NonConformingFloat {
            /// Throw upon encountering non-conforming values. This is the default strategy.
            case `throw`
            /// Decode the values from the given representation strings.
            case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
        }
    }
}

extension Configuration.Strategy {
    /// The strategy to use for decoding `Date` values.
    public enum DateDecoding {
        /// Defer to `Date` for decoding.
        case deferredToDate
        /// Decode the `Date` as a UNIX timestamp from a number.
        case secondsSince1970
        /// Decode the `Date` as UNIX millisecond timestamp from a number.
        case millisecondsSince1970
        /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        case iso8601
        /// Decode the `Date` as a string parsed by the given formatter.
        case formatted(DateFormatter)
        /// Decode the `Date` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Foundation.Date)
    }
    
    /// The strategy to use for encoding `Date` values.
    public enum DateEncoding {
        /// Defer to `Date` for choosing an encoding.
        case deferredToDate
        /// Encode the `Date` as a UNIX timestamp (as a number).
        case secondsSince1970
        /// Encode the `Date` as UNIX millisecond timestamp (as a number).
        case millisecondsSince1970
        /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        case iso8601
        /// Encode the `Date` as a string formatted by the given formatter.
        case formatted(DateFormatter)
        /// Encode the `Date` as a custom value encoded by the given closure.
        ///
        /// If the closure fails to encode a value into the given encoder, the encoder will encode an empty automatic container in its place.
        case custom((Date, Encoder) throws -> Void)
    }
}

extension Configuration.Strategy {
    /// The strategy to use for decoding `Data` values.
    public enum DataDecoding {
        /// Defer to `Data` for decoding.
        case deferredToData
        /// Decode the `Data` from a Base64-encoded string.
        case base64
        /// Decode the `Data` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Foundation.Data)
    }
    
    /// The strategy to use for encoding `Data` values.
    public enum DataEncoding {
        /// Defer to `Data` for choosing an encoding.
        case deferredToData
        /// Encoded the `Data` as a Base64-encoded string.
        case base64
        /// Encode the `Data` as a custom value encoded by the given closure.
        ///
        /// If the closure fails to encode a value into the given encoder, the encoder will encode an empty automatic container in its place.
        case custom((Data, Encoder) throws -> Void)
    }
}
