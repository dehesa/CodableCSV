import Foundation

// Decoding container that is accessed in random access similar to a dictionary.
internal protocol DecodingRandomContainer: class, DecodingContainer, RollBackable, KeyedDecodingContainerProtocol {
    /// Fetches the subcontainer at the position indicated by the coding key.
    ///
    /// This function will throw erros in the following cases:
    /// - The target key indicate a position that has already been parsed.
    /// - The decoder encountered invalid data while parsing rows.
    /// - The container doesn't have more data to decode.
    /// - The decoded container is not a single `String`.
    /// - parameter type: The type of the field to fetch. Mainly used for error throwing information.
    /// - parameter key: The key that the decoded value is associated with.
    /// - throws: `DecodingError` exclusively.
    func fetch(_ type: Any.Type, forKey key: Key) throws -> String
    
    /// Take a peak on how the value located in `key` will be.
    /// - parameter type: The type of the field to fetch. Mainly used for error throwing information.
    /// - parameter key: The key that the decoded value is associated with.
    /// - throws: `DecodingError` exclusively.
    func peak(_ type: Any.Type, forKey key: Key) throws -> String?
    
    /// Move the source pointer right before the given position.
    func moveBefore(key: Key) throws
    
    /// Move the source pointer forward one position.
    func moveForward() throws
}

extension DecodingRandomContainer {
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        let field = try self.fetch(type, forKey: key)
        guard let result = field.decodeToBool() else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        let field = try self.fetch(type, forKey: key)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        let field = try self.fetch(type, forKey: key)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        let field = try self.fetch(type, forKey: key)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        let field = try self.fetch(type, forKey: key)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        let field = try self.fetch(type, forKey: key)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        let field = try self.fetch(type, forKey: key)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        let field = try self.fetch(type, forKey: key)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        let field = try self.fetch(type, forKey: key)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        let field = try self.fetch(type, forKey: key)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        let field = try self.fetch(type, forKey: key)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        let field = try self.fetch(type, forKey: key)
        guard let result = field.decodeToFloat(self.decoder.source.configuration.floatStrategy) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        let field = try self.fetch(type, forKey: key)
        guard let result = field.decodeToDouble(self.decoder.source.configuration.floatStrategy) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        return try self.fetch(type, forKey: key)
    }
    
    func decode<T:Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        // 1. Is the target a single field/value?
        if let field = try self.peak(type, forKey: key) {
            // 1.1. Is the type asked for supported?
            if let result = try field.decodeToSupportedType(type, decoder: self.decoder) {
                try self.moveForward()
                return result
                // 1.2. Throw a generic single value container.
            } else {
                let result = try T(from: decoder)
                try self.moveForward()
                return result
            }
        // 2. The target is a container of multiple fields.
        } else {
            return try T(from: self.decoder)
        }
    }
    
    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
        guard let field = try self.peak(type, forKey: key),
              let result = field.decodeToBool() else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
        guard let field = try self.peak(type, forKey: key),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
        guard let field = try self.peak(type, forKey: key),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
        guard let field = try self.peak(type, forKey: key),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
        guard let field = try self.peak(type, forKey: key),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
        guard let field = try self.peak(type, forKey: key),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
        guard let field = try self.peak(type, forKey: key),
            let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
        guard let field = try self.peak(type, forKey: key),
            let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
        guard let field = try self.peak(type, forKey: key),
            let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
        guard let field = try self.peak(type, forKey: key),
            let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
        guard let field = try self.peak(type, forKey: key),
            let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
        guard let field = try self.peak(type, forKey: key),
            let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
        guard let field = try self.peak(type, forKey: key),
            let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
        guard let field = try self.peak(type, forKey: key) else { return nil }
        try self.moveForward()
        return field
    }
    
    func decodeIfPresent<T:Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
        // 1. Is the target a single field/value?
        if let field = try self.peak(type, forKey: key) {
            do {
                // 1.1. Is the type asked for supported?
                if let result = try field.decodeToSupportedType(type, decoder: self.decoder) {
                    try self.moveForward()
                    return result
                    // 1.2. Throw a generic single value container.
                } else {
                    let result = try T(from: decoder)
                    try self.moveForward()
                    return result
                }
            } catch { return nil }
        // 2. The target is a container of multiple fields.
        } else{
            var pointer = self
            return pointer.rollBackOnNil {
                try? T(from: self.decoder)
            }
        }
    }
}
