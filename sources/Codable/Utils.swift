import Foundation

extension DateFormatter {
    /// `DateFormatter` for ISO 8610 date formats.
    internal static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }()
}

infix operator ?!

extension Optional {
    /// Checks whether the value exists. If so, it returns the value; if not, it throws the given error.
    /// - parameter lhs: Optional value to check for existance.
    /// - parameter rhs: Swift error to throw in case of no value.
    /// - returns: The value (non-optional) passed as parameter.
    /// - throws: The Swift error returned on the right hand-side autoclosure.
    @inline(__always) internal static func ?!(lhs: Self, rhs: @autoclosure ()->Swift.Error) throws -> Wrapped {
        switch lhs {
        case .some(let v): return v
        case .none: throw rhs()
        }
    }
}
