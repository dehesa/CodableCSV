import Foundation

extension ShadowEncoder {
    /// Container that will hold a CSV record.
    ///
    /// This container can access its data in random order, such as a dictionary.
    internal final class EncodingRecordRandom<Key:CodingKey>: RecordEncodingContainer, EncodingRandomContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            fatalError()
            
//            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        func encodeNil(forKey key: Key) throws {
            #warning("TODO")
            fatalError()
        }
        
        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            #warning("TODO")
            fatalError()
        }
        
        func encodeConditional<T>(_ object: T, forKey key: Key) throws where T: AnyObject & Encodable {
            #warning("TODO")
            fatalError()
        }
        
        func encodeIfPresent<T:Encodable>(_ value: T?, forKey key: Key) throws {
            #warning("TODO")
            fatalError()
        }
        
        func nestedContainer<NestedKey:CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            #warning("TODO: Move before key.")
            return self.encoder.container(keyedBy: keyType)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            #warning("TODO: Move before key.")
            return self.encoder.unkeyedContainer()
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            #warning("TODO:")
            fatalError()
        }
    }
}
