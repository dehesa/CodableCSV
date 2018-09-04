import Foundation

extension Bool {
    /// Returns a `String` representing the receiving Boolean value.
    internal var asString: String {
        return String(self)
    }
}

extension String {
    /// Returns a `String` representing a `nil` value.
    internal static func nilRepresentation() -> String {
        return ""
    }
    
    /// Returns a `String` representing the passed floating-point value.
    /// - parameter value: The floating-point number to transform to a `String`.
    /// - parameter strategy: The rules on how to transform a floating-point number to a `String`.
    internal static func floatingPointRepresentation<T>(_ value: T, strategy: Strategy.NonConformingFloat) -> String? where T: FloatingPoint & LosslessStringConvertible {
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
    
    ///
//    internal func supportedTypeRepresentation<T:Encodable>(_ value: T, encoder: ShadowEncoder) throws -> String? {
//        if T.self == Foundation.Date.self {
//
//        } else if T.self == Foundation.Data.self {
//
//        } else if T.self == Foundation.URL.self {
//            return (value as! URL).absoluteString
//        } else if T.self == Foundation.Decimal.self {
//            let decimal = value as! Decimal
//            guard !decimal.isNaN else {
//                let context: EncodingError.Context = .init(codingPath: <#T##[CodingKey]#>, debugDescription: "The decimal value provided \"\(decimal)\" is not a number.")
//                throw EncodingError.invalidValue(value, context)
//            }
//        } else {
//            return nil
//        }
//    }
}

extension Date {
    /// Returns a `String` representing the receiving `Date` value.
    /// - parameter strategy: Strategy used to encode a `Date` value.
    internal func asString(strategy: Strategy.DateEncoding) -> String {
        switch strategy {
        case .secondsSince1970:
            return String(self.timeIntervalSince1970)
        case .millisecondsSince1970:
            return String(1000.0 * self.timeIntervalSince1970)
        case .iso8601:
            return DateFormatter.iso8601.string(from: self)
        case .formatted(let formatter):
            return formatter.string(from: self)
//        case .deferredToDate:
//            try self.encode(to: <#T##Encoder#>)
//        case .custom(let closure):
//            try closure(self, <#Encoder#>)
        default:
            #warning("TODO: Look this up, because the Date initializer will create a further singleValueContainer when in deffered or costum mode.")
            fatalError()
        }
    }
}

extension Data {
    /// Returns a `String` representing the receiving `Data` value.
    /// - parameter strategy: Strategy to encode a `Data` value.
    internal func asString(strategy: Strategy.DataEncoding) -> String {
        switch strategy {
        case .base64:
            return self.base64EncodedString()
        default:
            #warning("TODO: Look this up, because the Date initializer will create a further singleValueContainer when in deffered or costum mode.")
            fatalError()
//        case .deferredToData:
//            try self.encode(to: <#T##Encoder#>)
//        case .custom(let closure):
//            try closure(self, <#T##Encoder#>)
        }
    }
}
