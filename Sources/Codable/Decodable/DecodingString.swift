import Foundation

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
    internal func decodeToFloat(_ strategy: Strategy.NonConformingFloat) -> Float? {
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
    
    /// Tries to decode a string representing a floating-point number into a Double.
    /// - parameter strategy: Strategy used to decode numbers representing non-conforming value numbers such as infinity or NaN.
    internal func decodeToDouble(_ strategy: Strategy.NonConformingFloat) -> Double? {
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
    
    /// Tries to decode a string representing a date.
    /// - parameter strategy: Strategy used to decode the CSV field into a date.
    /// - parameter decoder: The decoder that can be passed around if the value needs to be wrapped in a container.
    private func decodeToDate(_ strategy: Strategy.DateDecoding, decoder generator: @autoclosure ()->ShadowDecoder) throws -> Foundation.Date {
        switch strategy {
        case .deferredToDate:
            let decoder = generator()
            do {
                //#warning("TODO: Look this up, because the Date initializer will create a further singleValueContainer.")
                return try Foundation.Date(from: decoder)
            } catch let error {
                let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "The string \"\(self)\" couldn't be transformed into a date using the \".deferredToDate\" strategy.", underlyingError: error)
                throw DecodingError.typeMismatch(Foundation.Date.self, context)
            }
        case .secondsSince1970:
            guard let number = Double(self) else {
                let context = DecodingError.Context(codingPath: generator().codingPath, debugDescription: "The string \"\(self)\" couldn't be transformed into a date using the \".secondsSince1970\" strategy.")
                throw DecodingError.dataCorrupted(context)
            }
            return Foundation.Date(timeIntervalSince1970: number)
        case .millisecondsSince1970:
            guard let number = Double(self) else {
                let context = DecodingError.Context(codingPath: generator().codingPath, debugDescription: "The string \"\(self)\" couldn't be transformed into a date using the \".millisecondsSince1970\" strategy.")
                throw DecodingError.dataCorrupted(context)
            }
            return Foundation.Date(timeIntervalSince1970: number / 1000.0)
        case .iso8601:
            guard let result = DateFormatter.iso8601.date(from: self) else {
                let context = DecodingError.Context(codingPath: generator().codingPath, debugDescription: "The string \"\(self)\" couldn't be transformed into a date using the \".iso8601\" strategy.")
                throw DecodingError.dataCorrupted(context)
            }
            return result
        case .formatted(let formatter):
            guard let result = formatter.date(from: self) else {
                let context = DecodingError.Context(codingPath: generator().codingPath, debugDescription: "The string \"\(self)\" couldn't be transformed into a date using the \".formatted(_)\" strategy.")
                throw DecodingError.dataCorrupted(context)
            }
            return result
        case .custom(let closure):
            let decoder = generator()
            do {
                return try closure(decoder)
            } catch let error {
                let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "The string \"\(self)\" couldn't be transformed into a date using the \".custom(_)\" strategy.", underlyingError: error)
                throw DecodingError.typeMismatch(Foundation.Date.self, context)
            }
        }
    }
    
    /// Tries to decode a string representing a data value.
    /// - parameter strategy: Strategy used to decode the CSV field into a date.
    /// - parameter decoder: The decoder that can be passed around if the value needs to be wrapped in a container.
    private func decodeToData(_ strategy: Strategy.DataDecoding, generator: @autoclosure ()->ShadowDecoder) throws -> Foundation.Data {
        switch strategy {
        case .deferredToData:
            let decoder = generator()
            do {
                return try Foundation.Data(from: decoder)
            } catch let error {
                let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "The following string couldn't be transformed into a data blob using the \".deferredToData\" strategy:\n\"\(self)\"", underlyingError: error)
                throw DecodingError.typeMismatch(Foundation.Date.self, context)
            }
        case .base64:
            guard let data = Data(base64Encoded: self) else {
                let context = DecodingError.Context(codingPath: generator().codingPath, debugDescription: "The following string is not valid Base64:\n\"\(self)\"")
                throw DecodingError.dataCorrupted(context)
            }
            return data
        case .custom(let closure):
            let decoder = generator()
            do {
                return try closure(decoder)
            } catch let error {
                let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "The following string couldn't be transformed into a data blob using the \".custom\" strategy:\n\"\(self)\"", underlyingError: error)
                throw DecodingError.typeMismatch(Foundation.Date.self, context)
            }
        }
    }
    
    /// Tries to decode a string into some predefined values.
    /// - parameter type: The type of the field to fetch. Mainly used for error throwing information.
    /// - parameter decoder: The decoder that can be passed around if the value needs to be wrapped in a container.
    /// - returns: A value if the generic type is supported, `nil` otherwise.
    internal func decodeToSupportedType<T:Decodable>(_ type: T.Type, decoder: ShadowDecoder) throws -> T? {
        let result: T
        
        if T.self == Foundation.Date.self {
            let strategy = decoder.source.configuration.dateStrategy
            result = try self.decodeToDate(strategy, decoder: decoder) as! T
        } else if T.self == Foundation.Data.self {
            let strategy = decoder.source.configuration.dataStrategy
            result = try self.decodeToData(strategy, generator: decoder) as! T
        } else if T.self == Foundation.URL.self {
            guard let url = URL(string: self) else {
                throw DecodingError.typeMismatch(type, .invalidTransformation(self, codingPath: decoder.codingPath))
            }
            result = url as! T
        } else if T.self == Foundation.Decimal.self {
            guard let number = Double(self) else {
                throw DecodingError.typeMismatch(type, .invalidTransformation(self, codingPath: decoder.codingPath))
            }
            result = Decimal(number) as! T
        } else {
            return nil
        }
        
        return result
    }
}
