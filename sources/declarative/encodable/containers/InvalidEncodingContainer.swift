internal extension ShadowEncoder {
    /// An encoding container that always fail.
    ///
    /// This container is created to circumvent the _non-throwing_ `Encoder` API.
    struct InvalidContainer<Key:CodingKey>: SingleValueEncodingContainer, UnkeyedEncodingContainer, KeyedEncodingContainerProtocol {
        /// The error to throw at all times.
        let error: Swift.Error
        /// The encoder containing the coding path.
        let encoder: ShadowEncoder
        
        init(error: Swift.Error, encoder: ShadowEncoder) {
            self.error = error
            self.encoder = encoder
        }
        
        var count: Int { 0 }
        var codingPath: [CodingKey] { self.encoder.codingPath }
        
        mutating func nestedContainer<NestedKey:CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            .init(InvalidContainer<NestedKey>(error: self.error, encoder: self.encoder))
        }
        mutating func nestedContainer<NestedKey:CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            self.nestedContainer(keyedBy: keyType)
        }
        
        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { self }
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer { self }
        mutating func superEncoder() -> Encoder { self.encoder }
        mutating func superEncoder(forKey key: Key) -> Encoder { self.encoder }
        
        mutating func encodeNil(forKey key: Key) throws { throw self.error }
        mutating func encodeNil() throws { throw self.error }
        mutating func encode<T:Encodable>(_ value: T, forKey key: Key) throws { throw self.error }
        mutating func encode<T:Encodable>(_ value: T) throws { throw self.error }
        mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element:Encodable { throw self.error }
        mutating func encodeConditional<T>(_ object: T) throws where T:AnyObject, T:Encodable { throw self.error }
    }
}
