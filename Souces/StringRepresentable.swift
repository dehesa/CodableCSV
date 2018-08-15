import Foundation

/// Provides a string and unicode scalar representation.
internal protocol StringRepresentable {
    /// Returns the actual string of characters representing the value separator.
    /// - returns: The String representation or `nil` if the value is unknown.
    /// - throws: The error passed on the `throwing` argument if the receiving instance contains invalid data.
    func string(throwing: (String)->Swift.Error) throws -> String?
    /// Returns the actual unicode scalars representing the value separator.
    /// - returns: The `UnicodeScalarView` representation or `nil` if the value is unknown.
    /// - throws: The error passed on the `throwing` argument if the receiving instance contains invalid data.
    func unicodeScalars(throwing: (String)->Swift.Error) throws -> String.UnicodeScalarView?
}

extension StringRepresentable {
    internal func unicodeScalars(throwing: (String)->Swift.Error) throws -> String.UnicodeScalarView? {
        guard let value = try self.string(throwing: throwing) else { return nil }
        let result = value.unicodeScalars
        return !result.isEmpty ? result : nil
    }
}

extension CSV.Delimiter.Field: StringRepresentable {
    internal func string(throwing: (String)->Swift.Error) throws -> String? {
        switch self {
        case .comma: return ","
        case .semicolon: return ":"
        case .tab: return "\t"
        case .unknown: return nil
        case .string(let delimiter):
            guard !delimiter.isEmpty else { throw throwing("Custom field delimiters must include at least one unicode scalar.") }
            return delimiter
        }
    }
}

extension CSV.Delimiter.Row: StringRepresentable {
    internal func string(throwing: (String)->Swift.Error) throws -> String? {
        switch self {
        case .lineFeed: return "\n"
        case .carriageReturn: return "\r"
        case .carriageReturnLineFeed: return "\r\n"
        case .unknown: return nil
        case .string(let delimiter):
            guard !delimiter.isEmpty else { throw throwing("Custom row delimiters must include at least one unicode scalar.") }
            return delimiter
        }
    }
}
