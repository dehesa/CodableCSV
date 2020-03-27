extension ShadowEncoder {
    /// Keyed container for the CSV shadow encoder.
    ///
    /// This container lets you randomly write CSV rows or specific fields within a single row.
    struct KeyedContainer<Key>: KeyedEncodingContainerProtocol where Key:CodingKey {
        /// The representation of the encoding process point-in-time.
        private let encoder: ShadowEncoder
        
        ///
        init(encoder: ShadowEncoder) {
            fatalError()
        }
        
        var codingPath: [CodingKey] {
            self.encoder.codingPath
        }
    }
}

extension ShadowEncoder.KeyedContainer {
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey:CodingKey {
        fatalError()
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError()
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        fatalError()
    }
}

extension ShadowEncoder.KeyedContainer {
    mutating func encode(_ value: String, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeNil(forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T:Encodable {
        fatalError()
    }
    
    mutating func encodeConditional<T>(_ object: T, forKey key: Key) throws where T:AnyObject, T:Encodable {
        fatalError()
    }
}

extension ShadowEncoder.KeyedContainer {
    mutating func encodeIfPresent(_ value: String?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeIfPresent<T>(_ value: T?, forKey key: Key) throws where T:Encodable {
        fatalError()
    }
}
