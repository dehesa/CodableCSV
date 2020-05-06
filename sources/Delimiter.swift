/// Separators scalars/strings.
public enum Delimiter {
    /// The CSV pair of delimiters (field & row delimiters).
    public typealias Pair = (field: Self.Field, row: Self.Row)
    /// The CSV pair of delimiter in string format.
    internal typealias RawPair = (field: [Unicode.Scalar], row: [Unicode.Scalar])
}

extension Delimiter {
    /// The delimiter between fields/values.
    public struct Field: ExpressibleByNilLiteral, ExpressibleByStringLiteral, RawRepresentable {
        public let rawValue: String.UnicodeScalarView
        
        public init(nilLiteral: ()) {
            self.rawValue = .init()
        }
        
        public init(unicodeScalarLiteral value: Unicode.Scalar) {
            self.rawValue = .init(repeating: value, count: 1)
        }
        
        public init(stringLiteral value: String) {
            self.rawValue = value.unicodeScalars
        }
        
        public init?(rawValue: String.UnicodeScalarView) {
            self.rawValue = rawValue
        }
        
        public init<S:StringProtocol>(_ value: S) {
            self.rawValue = String.UnicodeScalarView(value.unicodeScalars)
        }
    }
}

extension Delimiter {
    /// The delimiter between rows.
    public struct Row: ExpressibleByNilLiteral, ExpressibleByStringLiteral, RawRepresentable {
        public let rawValue: String.UnicodeScalarView
        
        public init(nilLiteral: ()) {
            self.rawValue = .init()
        }
        
        public init(unicodeScalarLiteral value: Unicode.Scalar) {
            self.rawValue = .init(repeating: value, count: 1)
        }
        
        public init(stringLiteral value: String) {
            self.rawValue = value.unicodeScalars
        }
        
        public init?(rawValue: String.UnicodeScalarView) {
            self.rawValue = rawValue
        }
        
        public init<S:StringProtocol>(_ value: S) {
            self.rawValue = String.UnicodeScalarView(value.unicodeScalars)
        }
    }
}
