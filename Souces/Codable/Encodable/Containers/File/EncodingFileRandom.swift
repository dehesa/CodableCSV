import Foundation

extension ShadowEncoder {
    /// Container which will hold all CSV records.
    ///
    /// This container can access its data in random order, such as a dictionary.
    internal final class EncodingFileRandom<Key:CodingKey>: FileEncodingContainer, EncodingRandomContainer {
        let codingKey: CSVKey = .file
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return self.superEncoder()
        }
    }
}

extension ShadowEncoder.EncodingFileRandom {
    func moveBefore(key: Key) throws {
        #warning("TODO")
        fatalError()
    }
    
    func encode(field: String, from value: Any, forKey key: Key) throws {
        #warning("TODO")
        fatalError()
    }
}
