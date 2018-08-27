import Foundation

/// Decoding container wrapping a single value.
internal protocol ValueContainer: DecodingContainer {
    /// Fetches the next subcontainer updating the indeces in the process.
    ///
    /// This function will throw erros in the following cases:
    /// - The decoder encountered invalid data while decoding the subcontainer.
    /// - The container doesn't have more data to decode.
    /// - The decoded container is not a single `String`.
    /// - parameter type: The type of the field to fetch. Mainly used for error throwing information.
    /// - throws: `DecodingError` exclusively.
    func fetchNext(_ type: Any.Type) throws -> String
}

extension ValueContainer {
    func decode(_ type: Bool.Type) throws -> Bool {
        let field = try self.fetchNext(type)
        guard let result = field.decodeToBool() else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        let field = try self.fetchNext(type)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        let field = try self.fetchNext(type)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        let field = try self.fetchNext(type)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        let field = try self.fetchNext(type)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        let field = try self.fetchNext(type)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        let field = try self.fetchNext(type)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        let field = try self.fetchNext(type)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        let field = try self.fetchNext(type)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        let field = try self.fetchNext(type)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        let field = try self.fetchNext(type)
        guard let result = type.init(field) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        let field = try self.fetchNext(type)
        guard let result = field.decodeToFloat(self.decoder.source.configuration.floatStrategy) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        let field = try self.fetchNext(type)
        guard let result = field.decodeToDouble(self.decoder.source.configuration.floatStrategy) else {
            throw DecodingError.mismatchError(string: field, codingPath: self.codingPath)
        }
        return result
    }
    
    func decode(_ type: String.Type) throws -> String {
        return try self.fetchNext(type)
    }
}
