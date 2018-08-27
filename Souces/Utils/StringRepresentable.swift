import Foundation

extension Unicode.Scalar {
    /// The quote unicode scalar used as escaping character.
    internal static let quote: Unicode.Scalar = "\""
}

/// Conforming instances return string or unicode scalar representations.
public protocol StringRepresentable {
    /// Returns a `String` representation of the receiving instance.
    var stringValue: String? { get }
}

extension StringRepresentable {
    /// Returns a `UnicodeScalarView` representation of the receiving instance.
    internal var unicodeScalars: String.UnicodeScalarView? {
        return self.stringValue?.unicodeScalars
    }
}

