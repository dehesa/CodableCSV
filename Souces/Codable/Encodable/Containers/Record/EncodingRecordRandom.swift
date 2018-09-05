import Foundation

extension ShadowEncoder {
    /// Container that will hold a CSV record.
    ///
    /// This container can access its data in random order, such as a dictionary.
    internal final class EncodingRecordRandom<Key:CodingKey>: RecordEncodingContainer, EncodingRandomContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            let index = try encoder.output.startNextRecord()
            self.codingKey = .record(index: index)
            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        init(encoder: ShadowEncoder, at recordIndex: Int) throws {
            try encoder.output.startRecord(at: recordIndex)
            let index = recordIndex
            self.codingKey = .record(index: index)
            self.encoder = try encoder.subEncoder(adding: self)
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
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            if let recordIndex = key.intValue {
                return self.encoder.unkeyedContainer(at: recordIndex)
            } else {
                return self.encoder.unkeyedContainer()
            }
        }
        
        func nestedContainer<NestedKey:CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            if let recordIndex = key.intValue {
                return self.encoder.container(at: recordIndex, keyedBy: keyType)
            } else {
                return self.encoder.container(keyedBy: keyType)
            }
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return self.superEncoder()
        }
    }
}

extension ShadowEncoder.EncodingRecordRandom {
    func encode(field: String, from value: Any, forKey key: Key) throws {
        #warning("TODO")
        fatalError()
    }
}
