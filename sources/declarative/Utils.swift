import Foundation

internal extension DateFormatter {
    /// `DateFormatter` for ISO 8610 date formats.
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }()
}

infix operator ?!

internal extension Optional {
    /// Checks whether the value exists. If so, it returns the value; if not, it throws the given error.
    /// - parameter lhs: Optional value to check for existance.
    /// - parameter rhs: Swift error to throw in case of no value.
    /// - returns: The value (non-optional) passed as parameter.
    /// - throws: The Swift error returned on the right hand-side autoclosure.
    @_transparent static func ?!(lhs: Self, rhs: @autoclosure ()->Swift.Error) throws -> Wrapped {
        switch lhs {
        case .some(let v): return v
        case .none: throw rhs()
        }
    }
}

internal extension Array where Element:Hashable {
    /// Creates a lookup dictionary for the receiving row.
    ///
    /// In case of two array element with the same hash value, the closure is executed and the generated error is thrown.
    /// - parameter error: The error being thrown on hash value collisions.
    func lookupDictionary(onCollision error: ()->Swift.Error) throws -> [Int:Int] {
        var lookup: [Int:Int] = .init(minimumCapacity: self.count)
        for (index, header) in self.enumerated() {
            let hash = header.hashValue
            guard case .none = lookup.updateValue(index, forKey: hash) else { throw error() }
        }
        return lookup
    }
}
