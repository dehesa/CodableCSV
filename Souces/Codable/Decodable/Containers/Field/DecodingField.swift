import Foundation

extension ShadowDecoder {
    /// A decoding container holding on a single field.
    internal final class DecodingField: FieldContainer, DecodingValueContainer, SingleValueDecodingContainer {
        let codingKey: CSVKey
        private(set) var decoder: ShadowDecoder!
        /// The field value.
        ///
        /// When the field is used once, the value is deleted.
        private(set) var value: String?
        
        init(decoder: ShadowDecoder) throws {
            switch decoder.chain.state {
            case .record(let container):
                let recordContainer = container as! RecordDecodingContainer
                self.codingKey = .field(index: recordContainer.currentIndex, recordIndex: recordContainer.recordIndex)
                self.value = recordContainer.record[recordContainer.currentIndex]
            case .field(let container):
                let fieldContainer = container as! DecodingField
                self.codingKey = fieldContainer.codingKey
                self.value = fieldContainer.value
            default:
                let context: DecodingError.Context = .init(codingPath: decoder.codingPath, debugDescription: "A field cannot be requested for the current codingPath.")
                throw DecodingError.typeMismatch(DecodingField.self, context)
            }
            
            self.decoder = try decoder.subDecoder(adding: self)
        }
        
        func decodeNil() -> Bool {
            // This function may return `true` the first time (when there is a value) and then return `false` (when the value has been used).
            guard let value = try? self.fetchNext(Any?.self) else {
                return false
            }
            return value.decodeToNil()
        }
        
        func decode<T:Decodable>(_ type: T.Type) throws -> T {
            guard let value = self.value else {
                throw DecodingError.valueNotFound(type, .isAtEnd(codingPath: self.codingPath))
            }
            
            if let result = try value.decodeToSupportedType(type, decoder: self.decoder) {
                self.value = nil
                return result
            } else {
                let result = try T(from: decoder)
                self.value = nil
                return result
            }
        }
    }
}

extension ShadowDecoder.DecodingField {
    func fetchNext(_ type: Any.Type) throws -> String {
        guard let value = self.value else {
            throw DecodingError.valueNotFound(type, .isAtEnd(codingPath: self.codingPath))
        }
        self.value = nil
        return value
    }
}
