import Foundation

extension ShadowEncoder {
    /// Encoding container used when an unkeyed or keyed containers have been queried at CSV field level.
    ///
    /// This containers can only encode a single value or they will start throwing errors.
    internal final class EncodingOrderedField: FieldContainer, EncodingOrderedContainer {
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
                throw EncodingError.invalidValue(EncodingOrderedField.self, context)
            }
        }
        
        var count: Int {
            return self.canEncode() ? 0 : 1
        }
    }
}

extension ShadowEncoder.EncodingOrderedField {
    func encodeNext(field: String, from value: Any) throws {
        guard canEncode() else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The encoding position \(self.codingKey) has been already encoded to.")
            throw EncodingError.invalidValue(value, context)
        }
        
        do {
            try self.encoder.output.encodeNext(field: field)
        } catch let error {
            throw EncodingError.invalidValue(value, .writingFailed(field: field, codingPath: self.codingPath, underlyingError: error))
        }
    }
    
    func encodeNext(record: [String], from sequence: Any) throws {
        guard record.count <= 1 else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "A CSV field cannot contain more than one value.")
            throw EncodingError.invalidValue(record, context)
        }
        
        try self.encodeNext(field: record.first ?? "", from: record)
    }
    
    /// Returns a Boolean indicating whether the field can get encoded.
    ///
    /// The reason to not be able to encode is that a value has already been encoded in the predefined position.
    private func canEncode() -> Bool {
        guard case .field(let field, let row) = self.codingKey else { return false }
        return (row, field) == self.encoder.output.indices
    }
}
