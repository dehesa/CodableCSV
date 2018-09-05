import Foundation

extension ShadowEncoder {
    /// Wraps a CSV file in a single value container.
    ///
    /// This container can encode data if the CSV file contains a single record and a single value (not counting the header).
    internal final class EncodingFileWrapper: WrapperFileContainer, WrapperEncodingContainer {
        let codingKey: CSVKey = .file
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        func encodeNil() throws {
            #warning("TODO")
            fatalError()
        }
        
        func encode<T:Encodable>(_ value: T) throws {
            #warning("TODO")
            fatalError()
        }
    }
}

extension ShadowEncoder.EncodingFileWrapper {
    func encodeNext(field: String, from value: Any) throws {
        #warning("TODO")
        fatalError()
    }
}
