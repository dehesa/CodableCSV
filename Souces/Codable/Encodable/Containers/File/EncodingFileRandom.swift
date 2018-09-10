import Foundation

extension ShadowEncoder {
    /// Container which will hold all CSV records.
    ///
    /// This container can access its data in random order, such as a dictionary.
    internal final class EncodingFileRandom<Key:CodingKey>: FileContainer, EncodingRandomContainer {
        let codingKey: CSVKey = .file
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return self.superEncoder()
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            #warning("TODO")
            fatalError()
//            if let recordIndex = key.intValue {
//                return self.encoder.unkeyedContainer(at: recordIndex)
//            } else {
//                return self.encoder.unkeyedContainer()
//            }
        }
        
        func nestedContainer<NestedKey:CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            #warning("TODO")
            fatalError()
//            if let recordIndex = key.intValue {
//                return self.encoder.container(at: recordIndex, keyedBy: keyType)
//            } else {
//                return self.encoder.container(keyedBy: keyType)
//            }
        }
    }
}

extension ShadowEncoder.EncodingFileRandom {
    func moveBefore(key: Key) throws {
//        guard let index = key.intValue else {
//            throw EncodingError.invalidValue("", .invalidKey(key, codingPath: self.codingPath))
//        }
    }
    
    func encode(field: String, from value: Any, forKey key: Key) throws {
        try self.moveBefore(key: key)
        #warning("TODO")
        fatalError()
    }
}
