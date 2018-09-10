import Foundation

internal protocol EncodingRandomContainer: EncodingContainer, KeyedEncodingContainerProtocol {
    /// Encodes the given field at the given key.
    /// - parameter field: The string value to be encoded.
    /// - parameter value: The value from which the field has been "distilled".
    /// - parameter key: The key at which the value will be encoded.
    /// - throws: `EncodingError` exclusively.
    func encode(field: String, from value: Any, forKey key: Key) throws
    
    /// Move the source pointer right before the given position.
    /// - throws: `EncodingError` exclusively.
    func moveBefore(key: Key) throws
}

extension EncodingRandomContainer {
    func encodeNil(forKey key: Key) throws {
        let result = String.nilRepresentation()
        try self.encode(field: result, from: "nil", forKey: key)
    }
    
    func encode(_ value: Bool, forKey key: Key) throws {
        let result = value.asString
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: Int, forKey key: Key) throws {
        let result = String(value)
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: Int8, forKey key: Key) throws {
        let result = String(value)
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: Int16, forKey key: Key) throws {
        let result = String(value)
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: Int32, forKey key: Key) throws {
        let result = String(value)
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: Int64, forKey key: Key) throws {
        let result = String(value)
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: UInt, forKey key: Key) throws {
        let result = String(value)
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: UInt8, forKey key: Key) throws {
        let result = String(value)
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: UInt16, forKey key: Key) throws {
        let result = String(value)
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: UInt32, forKey key: Key) throws {
        let result = String(value)
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: UInt64, forKey key: Key) throws {
        let result = String(value)
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: Float, forKey key: Key) throws {
        let strategy = self.encoder.output.configuration.floatStrategy
        guard let result = String.floatingPointRepresentation(value, strategy: strategy) else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The `Float` value \(value) couldn't be transformed to a String following the encoding strategy: \(strategy)")
            throw EncodingError.invalidValue(value, context)
        }
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: Double, forKey key: Key) throws {
        let strategy = self.encoder.output.configuration.floatStrategy
        guard let result = String.floatingPointRepresentation(value, strategy: strategy) else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The `Double` value \(value) couldn't be transformed to a String following the encoding strategy: \(strategy)")
            throw EncodingError.invalidValue(value, context)
        }
        try self.encode(field: result, from: value, forKey: key)
    }
    
    func encode(_ value: String, forKey key: Key) throws {
        try self.encode(field: value, from: value, forKey: key)
    }
    
    func encode<T:Encodable>(_ value: T, forKey key: Key) throws {
        switch String.supportedTypeRepresentation(value, configuration: self.encoder.output.configuration) {
        case .string(let field):
            try self.encode(field: field, from: value, forKey: key)
        case .inherited:
            try self.moveBefore(key: key)
            try value.encode(to: self.encoder)
        case .encoding(let closure):
            try self.moveBefore(key: key)
            try closure(encoder)
        case .error(let message):
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: message)
            throw EncodingError.invalidValue(value, context)
        }
    }
    
    func encodeConditional<T>(_ object: T, forKey key: Key) throws where T: AnyObject & Encodable {
        //#warning("TODO: Conditional encoding is currently unsupported.")
        return try self.encode(object, forKey: key)
    }
    
    func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent(_ value: String?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
    
    func encodeIfPresent<T:Encodable>(_ value: T?, forKey key: Key) throws {
        guard let value = value else { return }
        try self.encode(value, forKey: key)
    }
}
