import Foundation

internal extension DateFormatter {
    /// `DateFormatter` for ISO 8610 date formats.
    internal static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        return formatter
    }()
}
