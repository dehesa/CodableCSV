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
        
        public init(nilLiteral: ()) { self = .none }
        
        public init(booleanLiteral value: BooleanLiteralType) {
            self = (value) ? .firstLine : .none
        }
    }
    
    /// The strategy to use for non-standard floating-point values (IEEE 754 infinity and NaN).
    public enum NonConformingFloat {
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        /// Decode the values from the given representation strings.
        case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
}
