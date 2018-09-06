import Foundation

extension ShadowEncoder {
    /// A encoding container holding on a single field.
    internal final class EncodingField: FieldContainer, EncodingValueContainer, SingleValueEncodingContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!

        init(encoder: ShadowEncoder) throws {
            switch encoder.chain.state {
            case .record(let container):
                self.codingKey = .field(index: encoder.output.indices.field, recordIndex: container.recordIndex)
            case .field(let container):
                self.codingKey = container.codingKey
            default:
                let context: EncodingError.Context = .init(codingPath: encoder.codingPath, debugDescription: "A field cannot be requested for the current codingPath.")
                throw EncodingError.invalidValue(EncodingField.self, context)
            }
            self.encoder = try encoder.subEncoder(adding: self)
        }
    }
}

extension ShadowEncoder.EncodingField {
    /// Returns a Boolean indicating whether the field can get encoded.
    ///
    /// The reason to not be able to encode is that a value has already been encoded in the predefined position.
    private func canEncode() -> Bool {
        guard case .field(let field, let row) = self.codingKey else { return false }
        return (row, field) == self.encoder.output.indices
    }
    
    func encodeNext(field: String, from value: Any) throws {
        guard canEncode() else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The encoding position \(self.codingKey) has been already encoded to.")
            throw EncodingError.invalidValue(value, context)
        }
        
        do {
            try self.encoder.output.encodeNext(field: field)
        } catch let error {
            throw EncodingError.writingFailed(field: field, value: value, codingPath: self.codingPath, underlyingError: error)
        }
    }
}
