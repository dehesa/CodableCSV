import Foundation

extension ShadowDecoder {
    /// A decoding container holding ont a single field.
    internal final class Field: ValueContainer, SingleValueDecodingContainer {
        let codingKey: CSV.Key
        private(set) var decoder: ShadowDecoder!
        /// The field value.
        ///
        /// When the field is used once, the value is deleted.
        private(set) var value: String?
        
        init(decoder: ShadowDecoder) throws {
            switch decoder.chain.state {
            case .record(let recordContainer):
                guard case .record(let recordIndex) = recordContainer.codingKey else { fatalError() }
                self.codingKey = CSV.Key.field(index: recordContainer.currentIndex, recordIndex: recordIndex)
                self.value = recordContainer.record[recordContainer.currentIndex]
            case .field(let fieldContainer):
                self.codingKey = fieldContainer.codingKey
                self.value = fieldContainer.value
            default:
                throw DecodingError.invalidContainer(codingPath: decoder.codingPath)
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
                throw DecodingError.isAtEnd(type, codingPath: self.codingPath)
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

extension ShadowDecoder.Field {
    func fetchNext(_ type: Any.Type) throws -> String {
        guard let value = self.value else {
            throw DecodingError.isAtEnd(type, codingPath: self.codingPath)
        }
        self.value = nil
        return value
    }
}
