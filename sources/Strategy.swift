/// The strategies to use when encoding/decoding.
public enum Strategy {
    /// Indication on whether the CSV file contains headers or not.
    public enum Header: ExpressibleByNilLiteral, ExpressibleByBooleanLiteral {
        /// The CSV contains no header row.
        case none
        /// The CSV contains a single header row.
        case firstLine
//        /// It is not known whether the CSV contains a header row. Try to infer it!
//        case unknown
        
        public init(nilLiteral: ()) {
            self = .none
        }
        
        public init(booleanLiteral value: BooleanLiteralType) {
            self = (value) ? .firstLine : .none
        }
    }
    
    /// The strategy to allow/disable escaped fields and how.
    public enum Escaping: ExpressibleByNilLiteral, ExpressibleByUnicodeScalarLiteral {
        /// CSV delimiters can not be escaped.
        case none
        /// Ignore delimiter with in a scalar pair.
        case scalar(Unicode.Scalar)

        /// Escape double quoted values.
        public static let doubleQuote: Self = "\""

        public init(nilLiteral: ()) {
            self = .none
        }
        
        public init(unicodeScalarLiteral value: Unicode.Scalar) {
            self = .scalar(value)
        }

        /// Unwraps (if any) the value stored in this enumeration.
        var scalar: Unicode.Scalar? {
            switch self {
            case .none: return nil
            case .scalar(let s): return s
            }
        }
    }

    /// The strategy for non-standard floating-point values (IEEE 754 infinity and NaN).
    public enum NonConformingFloat {
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        /// Decode the values from the given representation strings.
        case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
}
