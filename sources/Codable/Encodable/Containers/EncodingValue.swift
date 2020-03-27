extension ShadowEncoder {
    ///
    struct SingleValueContainer {
        /// The representation of the encoding process point-in-time.
        private let encoder: ShadowEncoder
        
        var codingPath: [CodingKey] {
            self.encoder.codingPath
        }
        
        init(encoder: ShadowEncoder) {
            fatalError()
        }
    }
}

extension ShadowEncoder.SingleValueContainer: SingleValueEncodingContainer {
    mutating func encode(_ value: String) throws {
        fatalError()
    }
    
    mutating func encodeNil() throws {
        fatalError()
    }
    
    mutating func encode(_ value: Bool) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int8) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int16) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int32) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int64) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt8) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt16) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt32) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt64) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Float) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Double) throws {
        fatalError()
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        fatalError()
    }
}
