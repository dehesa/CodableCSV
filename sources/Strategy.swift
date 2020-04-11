/// The strategies to use when encoding/decoding.
public enum Strategy {
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
        internal var scalar: Unicode.Scalar? {
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
        /// Encodes/Decodes the values from/to the given representation strings.
        case convert(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
}
