import Foundation

extension ShadowEncoder {
    /// Wraps a CSV file in a single value container.
    ///
    /// This container can encode data if the CSV file contains a single record and a single value (not counting the header).
    internal final class EncodingFileWrapper: WrapperEncodingContainer, WrapperFileContainer {
        let codingKey: CSVKey = .file
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            self.encoder = try encoder.subEncoder(adding: self)
        }
    }
}
