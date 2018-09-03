import Foundation

extension ShadowEncoder {
    /// Container which will hold all CSV records.
    ///
    /// This container can access its data in random order, such as a dictionary.
    internal final class EncodingFileRandom<Key:CodingKey>: FileEncodingContainer {
        let codingKey: CSVKey = .file
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            self.encoder = try encoder.subEncoder(adding: self)
        }
    }
}
