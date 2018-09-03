import Foundation

extension Bool {
    /// Returns a `String` representing the receiving Boolean value.
    internal func encodeToString() -> String {
        return String(self)
    }
}

extension String {
    /// Returns a `String` representing a `nil` value.
    internal static func encodeNil() -> String {
        return ""
    }
    
    /// Returns a `String` representing the passed floating-point value.
    /// - parameter value: The floating-point number to transform to a `String`.
    /// - parameter strategy: The rules on how to transform a floating-point number to a `String`.
    internal static func encodeFloatingPoint<T>(_ value: T, strategy: Configuration.Strategy.NonConformingFloat) -> String? where T: FloatingPoint & LosslessStringConvertible {
        if value.isNaN {
            guard case .convertFromString(_, _, let nan) = strategy else { return nil }
            return nan
        } else if value.isInfinite {
            guard case .convertFromString(let positiveInf, let negativeInf, _) = strategy else { return nil }
            return (value ==  T.infinity) ? positiveInf :
                   (value == -T.infinity) ? negativeInf : nil
        } else {
            return String(value)
        }
    }
}

extension Date {
    /// Returns a `String` representing the receiving `Date` value.
    /// - parameter strategy: Strategy used to encode a Date value.
//    internal func encodeToString(_ strategy: Configuration.Strategy.Date) throws -> String {
//        switch strategy {
//        case .deferredToDate:
//            #warning("TODO: Look this up, because the Date initializer will create a further singleValueContainer.")
//
//        default:
//            fatalError()
//        }
//    }
}
