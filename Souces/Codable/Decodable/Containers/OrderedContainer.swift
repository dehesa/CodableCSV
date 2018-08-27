import Foundation

/// Decoding container that is accessed in order similar to an array.
internal protocol OrderedContainer: ValueContainer, UnkeyedDecodingContainer {
    /// Peaks on the next subcontainer without actually updating the source pointers.
    /// - throws: `DecodingError` exclusively.
    func peakNext() -> String?
    
    /// Move the source pointer forward one position.
    func moveForward() throws
}

extension OrderedContainer {
    func decode<T:Decodable>(_ type: T.Type) throws -> T {
        guard !self.isAtEnd else { throw DecodingError.isAtEnd(type, codingPath: self.codingPath) }
        
        if let _ = self.peakNext() {
            #warning("If the init(from:) calls a SingleValueDecodingContainer, this will throw an error. This needs to be fixed, so the decodingChain will accept a single value after a file.")
            let result = try self.decoder.singleValueContainer().decode(type)
            try self.moveForward()
            return result
        } else {
            return try T(from: self.decoder)
        }
    }
    
    func decodeIfPresent<T:Decodable>(_ type: T.Type) throws -> T? {
        guard !self.isAtEnd else { return nil }
        
        if let _ = self.peakNext() {
            let container = try self.decoder.singleValueContainer()
            guard let result = try? container.decode(type) else { return nil }
            try self.moveForward()
            return result
        } else {
            #warning("This is probably NOT right. Maybe do rollbacks?")
            return try? T(from: self.decoder)
        }
    }
    
    func decodeIfPresent(_ type: Bool.Type) throws -> Bool? {
        guard let field = self.peakNext(),
              let result = field.decodeToBool() else { return nil }
        try self.moveForward()
        return result
    }

    func decodeIfPresent(_ type: String.Type) throws -> String? {
        guard let field = self.peakNext() else { return nil }
        try self.moveForward()
        return field
    }
    
    func decodeIfPresent(_ type: Double.Type) throws -> Double? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }

    func decodeIfPresent(_ type: Float.Type) throws -> Float? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Int.Type) throws -> Int? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Int8.Type) throws -> Int8? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Int16.Type) throws -> Int16? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Int32.Type) throws -> Int32? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Int64.Type) throws -> Int64? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: UInt.Type) throws -> UInt? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: UInt8.Type) throws -> UInt8? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: UInt16.Type) throws -> UInt16? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: UInt32.Type) throws -> UInt32? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: UInt64.Type) throws -> UInt64? {
        guard let field = self.peakNext(),
              let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
}
