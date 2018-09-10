import Foundation

extension ShadowEncoder {
    ///
    internal final class EncodingRandomField<Key:CodingKey>: FieldContainer, EncodingRandomContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            switch encoder.chain.state {
            case .record(let container):
                self.codingKey = .field(index: encoder.output.indices.field, recordIndex: container.recordIndex)
            case .field(let container):
                self.codingKey = container.codingKey
            case .overview, .file:
                let context: EncodingError.Context = .init(codingPath: encoder.codingPath, debugDescription: "This type of container cannot be queried at this point in the encoding chain.")
                throw EncodingError.invalidValue(EncodingRandomField.self, context)
            }
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return self.superEncoder()
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            #warning("TODO")
            fatalError()
        }
        
        func nestedContainer<NestedKey:CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            #warning("TODO")
            fatalError()
        }
    }
}

extension ShadowEncoder.EncodingRandomField {
    func encode(field: String, from value: Any, forKey key: Key) throws {
        fatalError()
    }
    
    func moveBefore(key: Key) throws {
        fatalError()
    }
    
    /// Returns a Boolean indicating whether the field can get encoded.
    ///
    /// The reason to not be able to encode is that a value has already been encoded in the predefined position.
    private func canEncode() -> Bool {
        guard case .field(let field, let row) = self.codingKey else { return false }
        return (row, field) == self.encoder.output.indices
    }
}
