extension ShadowEncoder {
    ///
    struct UnkeyedContainer: UnkeyedEncodingContainer {
        /// The representation of the encoding process point-in-time.
        private let encoder: ShadowEncoder
        
        init(encoder: ShadowEncoder) {
            fatalError()
        }
        
        var codingPath: [CodingKey] {
            self.encoder.codingPath
        }
        
        var count: Int {
            fatalError()
        }
    }
}

extension ShadowEncoder.UnkeyedContainer {
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError()
    }
}

extension ShadowEncoder.UnkeyedContainer {
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
    
    mutating func encodeConditional<T>(_ object: T) throws where T:AnyObject, T:Encodable {
        fatalError()
    }
}

extension ShadowEncoder.UnkeyedContainer {
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==String {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Bool {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Int {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Int8 {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Int16 {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Int32 {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Int64 {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==UInt {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==UInt8 {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==UInt16 {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==UInt32 {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==UInt64 {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Float {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Double {
        fatalError()
    }
    
    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element:Encodable {
        fatalError()
    }
}
