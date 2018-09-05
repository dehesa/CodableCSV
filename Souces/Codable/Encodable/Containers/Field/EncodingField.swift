import Foundation

extension ShadowEncoder {
    /// A encoding container holding on a single field.
    internal final class EncodingField: FieldContainer, EncodingValueContainer, SingleValueEncodingContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!

        init(encoder: ShadowEncoder) throws {
//            switch encoder.chain.state {
//            case .record(let container):
//                let recordContainer = container as! RecordContainer
//            }
//            self.encoder = try encoder.subEncoder(adding: self)
            fatalError()
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

extension ShadowEncoder.EncodingField {
    func encodeNext(field: String, from value: Any) throws {
        #warning("TODO")
        fatalError()
    }
}
