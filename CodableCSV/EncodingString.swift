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
    
    /// A representation of supported basic types.
    internal enum EncodingRepresentation {
        // The `value.encode(to: encoder)` should be called on it.
        case inherited
        /// The representation can be made with a `String`.
        case string(String)
        /// The passed closure will encode the value with a given encoder.
        /// - note: The result may create several fields or records.
        case encoding((Encoder) throws -> ())
        /// The message of the error that will be thrown.
        case error(message: String)
    }
    
    /// Returns a representation of the passed value.
    /// - parameter value: The value to encode.
    /// - parameter configuration: The encoding configuration.
    internal static func supportedTypeRepresentation<T:Encodable>(_ value: T, configuration: EncoderConfiguration) -> EncodingRepresentation {
        switch value {
        case let date as Date:
            return String.dateRepresentation(date, strategy: configuration.dateStrategy)
        case let data as Data:
            return String.dataRepresentation(data, strategy: configuration.dataStrategy)
        case let url as URL:
            return .string(url.absoluteString)
        case let decimal as Decimal:
            guard !decimal.isNaN else {
                return .error(message: "The decimal value provided \"\(decimal)\" is not a number.")
            }
            return .string(decimal.description)
        default:
            return .inherited
        }
    }
    
    /// Returns a representation of the passed `Date` value.
    /// - parameter value: The `Date` value to be encoded.
    /// - parameter strategy: Strategy used to encode a `Date` value.
    internal static func dateRepresentation(_ value: Date, strategy: Strategy.DateEncoding) -> EncodingRepresentation {
        switch strategy {
        case .deferredToDate:
            return .inherited
        case .secondsSince1970:
            return .string(String(value.timeIntervalSince1970))
        case .millisecondsSince1970:
            return .string(String(1000.0 * value.timeIntervalSince1970))
        case .iso8601:
            return .string(DateFormatter.iso8601.string(from: value))
        case .formatted(let formatter):
            return .string(formatter.string(from: value))
        case .custom(let closure):
            return .encoding({ try closure(value, $0) })
        }
    }
    
    /// Returns a representation of the passed `Data` value.
    /// - parameter value: The `Data` value to be encoded.
    /// - parameter strategy: Strategy to encode a `Data` value.
    internal static func dataRepresentation(_ value: Data, strategy: Strategy.DataEncoding) -> EncodingRepresentation {
        switch strategy {
        case .base64:
            return .string(value.base64EncodedString())
        case .deferredToData:
            return .inherited
        case .custom(let closure):
            return .encoding({ try closure(value, $0) })
        }
    }
}
