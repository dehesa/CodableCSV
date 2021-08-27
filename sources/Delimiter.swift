/// Separators scalars/strings.
public enum Delimiter {
  /// The CSV pair of delimiters (field & row delimiters).
  public typealias Pair = (field: Self.Field, row: Self.Row)
}

extension Delimiter {
  /// The delimiter between fields/values.
  ///
  /// If the delimiter is initialized with `nil`, it implies the field delimiter is unknown and the system should try to figure it out.
  public struct Field: ExpressibleByNilLiteral, ExpressibleByStringLiteral, CustomStringConvertible {
    /// The accepted field delimiter. Usually a comma `,`.
    ///
    /// If it's empty, the field delimiter is unknown.
    let scalars: [Unicode.Scalar]

    public init(nilLiteral: ()) {
      self.scalars = Array()
    }

    public init(unicodeScalarLiteral value: Unicode.Scalar) {
      self.scalars = [value]
    }

    public init(stringLiteral value: String) {
      precondition(!value.isEmpty)
      self.scalars = Array(value.unicodeScalars)
    }

    /// The field delimiter is represented by the given `String`-like type.
    /// - parameter delimiter: The exact composition of the field delimiter. If empty, the initializer fails returning `nil`.
    public init?<S:StringProtocol>(_ delimiter: S) {
      guard !delimiter.isEmpty else { return nil }
      self.scalars = Array(delimiter.unicodeScalars)
    }

    /// Boolean indicating if the exact unicode scalar composition for the field delimiter is known or unknown.
    var isKnown: Bool {
      !self.scalars.isEmpty
    }

    /// Returns the `String` representation of the field delimiter.
    public var description: String {
      String(String.UnicodeScalarView(self.scalars))
    }
  }
}

extension Delimiter {
  /// The delimiter between rows.
  ///
  /// If the delimiter is initialized with `nil`, it implies the row delimiter is unknown and the system should try to figure it out.
  public struct Row: ExpressibleByStringLiteral, ExpressibleByNilLiteral, CustomStringConvertible {
    /// All the accepted row delimiters. Usually, it is only one.
    /// - invariant: The elements of the set (i.e. the arrays) always contain at least one element.
    let scalars: Set<[Unicode.Scalar]>

    public init(nilLiteral: ()) {
      self.scalars = Set()
    }

    public init(unicodeScalarLiteral value: Unicode.Scalar) {
      var delimiters = Set<[Unicode.Scalar]>(minimumCapacity: 1)
      delimiters.insert([value])
      self.scalars = delimiters
    }

    public init(stringLiteral value: String) {
      precondition(!value.isEmpty)

      var delimiters = Set<[Unicode.Scalar]>(minimumCapacity: 1)
      delimiters.insert(Array(value.unicodeScalars))
      self.scalars = delimiters
    }

    /// Creates one or more possible row delimiters.
    /// - parameter delimiters:The exact composition of the row delimiters. If any of the `delimiters` is empty, the initializer fails returning `nil`.
    public init?<S:StringProtocol>(_ delimiters: S...) {
      let scalars: [[Unicode.Scalar]] = delimiters.compactMap {
        guard !$0.isEmpty else { return nil }
        return Array($0.unicodeScalars)
      }
      guard !scalars.isEmpty else { return nil }
      self.scalars = Set(scalars)
    }

    /// Specifies two row delimiters: CR (Carriage Return) LF (Line Feed) `\r\n` and s single line feed `\n`.
    ///
    /// This delimiter is intended to be used with CSVs where the end of the row may be marked with a CRLF sometimes and other times with LF.
    public static var standard: Self {
      self.init("\n", "\r\n")!
    }

    /// Boolean indicating if the exact unicode scalar composition for the row delimiter is known or unknown.
    var isKnown: Bool {
      !self.scalars.isEmpty
    }

    /// Returns the `String` representation of the row delimiter.
    ///
    /// If more than one row has been provided, the `String` with less number of characters and less value (i.e. less Integer value) is selected.
    public var description: String {
      String(String.UnicodeScalarView(self.scalars.min {
        guard $0.count == $1.count else { return $0.count < $1.count }
        for (lhs, rhs) in zip($0, $1) where lhs != rhs { return lhs < rhs }
        return true
      }!))
    }
  }
}

extension Delimiter {
  /// Contains the exact composition of a CSV field and row delimiter.
  struct Scalars {
    /// The exact composition of unicode scalars indetifying a field delimiter.
    /// - invariant: The array always contains at least one element.
    let field: [Unicode.Scalar]
    /// All possile row delimiters specifying its exact compositon of unicode scalars.
    /// - invariant: The set always contains at least one element and all set elements always contain at least on scalar.
    let row: Set<[Unicode.Scalar]>

    /// Designated initializer checking that the delimiters aren't empty and the field delimiter is not included in the row delimiter.
    /// - parameter field: The exact composition of the field delimiter. If empty, `nil` is returned.
    /// - parameter row: The exact composition of all possible row delimiters. If it is empty or any of its elements is an empty array, `nil` is returned.
    init?(field: [Unicode.Scalar], row: Set<[Unicode.Scalar]>) {
      guard !field.isEmpty else { return nil }
      self.field = field
      guard !row.isEmpty, row.allSatisfy({ !$0.isEmpty }) else { return nil }
      self.row = row
      guard self.row.allSatisfy({ $0 != self.field }) else { return nil }
    }
  }
}
