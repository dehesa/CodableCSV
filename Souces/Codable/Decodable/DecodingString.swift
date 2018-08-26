import Foundation

private let iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()

extension String {
    /// Returns a Boolean indicating whether the receiving string is empty (represents `nil`) or not.
    internal func decodeToNil() -> Bool {
        return self.isEmpty
    }
    
    /// Parses the receiving String looking for specific character chains representing a `true` or `false` value.
    /// - returns: A Boolean if the string could be transformed, or `nil` if the transformation was unsuccessful.
    internal func decodeToBool() -> Bool? {
        switch self.uppercased() {
        case "TRUE", "YES": return true
        case "FALSE", "NO", "": return false
        default: return nil
        }
    }
    
    /// Tries to decode a string representing a floating-point number into a Double.
    /// - parameter strategy: Strategy used to decode numbers representing non-conforming value numbers such as infinity or NaN.
    internal func decodeToDouble(_ strategy: CSV.Strategy.NonConformingFloat) -> Double? {
        if let result = Double(self) {
            return result
        } else if case .convertFromString(let positiveInfinity, let negativeInfinity, let nanSymbol) = strategy {
            switch self {
            case positiveInfinity: return  Double.infinity
            case negativeInfinity: return -Double.infinity
            case nanSymbol: return Double.nan
            default: break
            }
        }
        
        return nil
    }
    
    /// Tries to decode a string representing a floating-point number into a Double.
    /// - parameter strategy: Strategy used to decode numbers representing non-conforming value numbers such as infinity or NaN.
    internal func decodeToFloat(_ strategy: CSV.Strategy.NonConformingFloat) -> Float? {
        if let result = Double(self) {
            return abs(result) <= Double(Float.greatestFiniteMagnitude) ? Float(result) : nil
        } else if case .convertFromString(let positiveInfinity, let negativeInfinity, let nanSymbol) = strategy {
            switch self {
            case positiveInfinity: return  Float.infinity
            case negativeInfinity: return -Float.infinity
            case nanSymbol: return Float.nan
            default: break
            }
        }
        
        return nil
    }
    
    /// Tries to decode a string representing a date.
    /// - parameter strategy:
//    internal func decodeToDate(_ strategy: CSV.Strategy.Date) -> Date? {
//        switch strategy {
//        case .deferredToDate:
//            // superDecoder?
//            // return Date(from: decoder)
//            break
//        case .secondsSince1970:
//            guard let number = Double(self) else { return nil }
//            return Date(timeIntervalSince1970: number)
//        case .millisecondsSince1970:
//            guard let number = Double(self) else { return nil }
//            return Date(timeIntervalSince1970: number / 1000.0)
//        case .iso8601:
//            return iso8601Formatter.date(from: self)
//        case .formatted(let formatter):
//            return formatter.date(from: self)
//        case .custom(let closure):
//            // superDecoder?
//            // return closure(decoder)
//        }
//    }
}
