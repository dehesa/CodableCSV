import Foundation

internal protocol EncodingValueContainer: EncodingContainer {
    /// Encodes the next subcontainer as a field updating the indeces in the process.
    ///
    /// This function will throw error in the following cases:
    /// - The encoder encountered invalid data while encoding the subcontainer.
    /// - The encoder cannot encode another field in the targeted row.
    /// - throws: `DecodingError` exclusively.
    func encodeNext(field: String, from value: Any) throws
}

extension EncodingValueContainer {
    func encode(_ value: Bool) throws {
        let result = value.asString
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: Int) throws {
        let result = String(value)
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: Int8) throws {
        let result = String(value)
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: Int16) throws {
        let result = String(value)
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: Int32) throws {
        let result = String(value)
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: Int64) throws {
        let result = String(value)
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: UInt) throws {
        let result = String(value)
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: UInt8) throws {
        let result = String(value)
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: UInt16) throws {
        let result = String(value)
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: UInt32) throws {
        let result = String(value)
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: UInt64) throws {
        let result = String(value)
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: Float) throws {
        let strategy = self.encoder.output.configuration.floatStrategy
        guard let result = String.floatingPointRepresentation(value, strategy: strategy) else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The `Float` value \(value) couldn't be transformed to a String following the encoding strategy: \(strategy)")
            throw EncodingError.invalidValue(value, context)
        }
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: Double) throws {
        let strategy = self.encoder.output.configuration.floatStrategy
        guard let result = String.floatingPointRepresentation(value, strategy: strategy) else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The `Double` value \(value) couldn't be transformed to a String following the encoding strategy: \(strategy)")
            throw EncodingError.invalidValue(value, context)
        }
        try self.encodeNext(field: result, from: value)
    }
    
    func encode(_ value: String) throws {
        try self.encodeNext(field: value, from: value)
    }
}
