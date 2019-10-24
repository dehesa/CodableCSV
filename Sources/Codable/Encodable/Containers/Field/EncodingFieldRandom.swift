import Foundation

extension ShadowEncoder {
    ///
    internal final class EncodingFieldRandom<Key:CodingKey>: FieldContainer, EncodingRandomContainer {
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
                throw EncodingError.invalidValue(EncodingFieldRandom.self, context)
            }
        }
    }
}

extension ShadowEncoder.EncodingFieldRandom {
    func moveBefore(key: Key) throws {
        guard let index = key.intValue else {
            throw EncodingError.invalidValue(key, .invalidKey(key, codingPath: self.codingPath))
        }
        
        guard case .field(let fieldIndex, let rowIndex) = self.codingKey,
              (rowIndex, fieldIndex) == self.encoder.output.indices, fieldIndex == index else {
            let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: "This container can only encode a single value and it must be the one right before the container was called.")
            throw EncodingError.invalidValue(index, context)
        }
    }
    
    func encode(field: String, from value: Any, forKey key: Key) throws {
        try moveBefore(key: key)
        
        do {
            try self.encoder.output.encodeNext(field: field)
        } catch let error {
            throw EncodingError.invalidValue(value, .writingFailed(field: field, codingPath: self.codingPath, underlyingError: error))
        }
    }
    
    /// Returns a Boolean indicating whether the field can get encoded.
    ///
    /// The reason to not be able to encode is that a value has already been encoded in the predefined position.
    private func canEncode() -> Bool {
        guard case .field(let field, let row) = self.codingKey else { return false }
        return (row, field) == self.encoder.output.indices
    }
}
