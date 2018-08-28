import Foundation

/// Decoding container that is accessed in order similar to an array.
internal protocol OrderedContainer: class, ValueContainer, RollBackable, UnkeyedDecodingContainer {
    /// Peaks on the next subcontainer without actually updating the source pointers.
    /// - returns: A `String` value when the following subcontainer holds a single value, or `nil` when the container is ats its end or the subcontainer holds multiple values.
    /// - throws: `DecodingError` exclusively.
    func peakNext() -> String?
    
    /// Move the source pointer forward one position.
    func moveForward() throws
}

extension OrderedContainer {
    func decode<T:Decodable>(_ type: T.Type) throws -> T {
        // 1. Is the target a single field/value?
        if let field = self.peakNext() {
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
        // 2. The target is a container of multiple fields. Is it at the end?
        } else if !self.isAtEnd {
            return try T(from: self.decoder)
        // 3. The target is a container of multiple fields and it is at the end.
        } else {
            throw DecodingError.isAtEnd(type, codingPath: self.codingPath)
        }
    }
    
    func decodeIfPresent(_ type: Bool.Type) throws -> Bool? {
        guard let field = self.peakNext(),
              let result = field.decodeToBool() else { return nil }
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
    
    func decodeIfPresent(_ type: Float.Type) throws -> Float? {
        guard let field = self.peakNext(),
            let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: Double.Type) throws -> Double? {
        guard let field = self.peakNext(),
            let result = type.init(field) else { return nil }
        try self.moveForward()
        return result
    }
    
    func decodeIfPresent(_ type: String.Type) throws -> String? {
        guard let field = self.peakNext() else { return nil }
        try self.moveForward()
        return field
    }
    
    func decodeIfPresent<T:Decodable>(_ type: T.Type) throws -> T? {
        // 1. Is the target a single field/value?
        if let field = self.peakNext() {
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
        // 2. The target is a container of multiple fields. Is it at the end?
        } else if !self.isAtEnd {
            var pointer = self
            return pointer.rollBackOnNil {
                try? T(from: self.decoder)
            }
        // 3. The target is a container of multiple fields and it is at the end.
        } else {
            return nil
        }
    }
}
