import Foundation

extension ShadowEncoder {
    /// Container that will hold a CSV record.
    ///
    /// This container can access its data in random order, such as a dictionary.
    internal final class EncodingRecordRandom<Key:CodingKey>: RecordEncodingContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            fatalError()
            
            self.encoder = try encoder.subEncoder(adding: self)
        }
    }
}
