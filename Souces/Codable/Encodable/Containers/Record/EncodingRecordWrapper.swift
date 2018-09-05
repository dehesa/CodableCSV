import Foundation

extension ShadowEncoder {
    /// Wraps a CSV record/row in a single value container.
    ///
    /// This container can encode data if the CSV record being pointed to contains a single field.
    internal final class EncodingRecordWrapper: WrapperRecordContainer, WrapperEncodingContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            fatalError()
            
//            self.encoder = try encoder.subEncoder(adding: self)
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

extension ShadowEncoder.EncodingRecordWrapper {
    func encodeNext(field: String, from value: Any) throws {
        #warning("TODO")
        fatalError()
    }
}
