import Foundation

protocol DateFormatterProtocol {
  func date(from string: String) -> Date?
  func string(from date: Date) -> String
}

internal extension DateFormatter {
  /// `DateFormatter` for ISO 8610 date formats.
  static let iso8601: DateFormatterProtocol = {
    if #available(OSX 10.12, *) {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = .withInternetDateTime
      return formatter
    } else {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.timeZone = TimeZone(secondsFromGMT: 0)
      formatter.calendar = Calendar(identifier: .iso8601)
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
      return formatter
    }
  }()
}

extension DateFormatter: DateFormatterProtocol {}

@available(OSX 10.12, *)
extension ISO8601DateFormatter: DateFormatterProtocol {}
