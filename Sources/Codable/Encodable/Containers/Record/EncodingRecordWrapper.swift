import Foundation

extension ShadowEncoder {
    /// Wraps a CSV record/row in a single value container.
    ///
    /// This container can encode data if the CSV record being pointed to contains a single field.
    internal final class EncodingRecordWrapper: WrapperRecordContainer, EncodingValueContainer, SingleValueEncodingContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        let recordIndex: Int
        
        init(encoder: ShadowEncoder) throws {
            self.recordIndex = encoder.output.indices.row
            self.codingKey = .record(index: self.recordIndex)
            self.encoder = try encoder.subEncoder(adding: self)
        }
    }
}

extension ShadowEncoder.EncodingRecordWrapper {
    func encodeNext(field: String, from value: Any) throws {
        guard self.recordIndex == self.encoder.output.indices.row else {
            throw EncodingError.invalidValue(value, .invalidRow(codingPath: self.codingPath))
        }
        
        do {
            try self.encoder.output.encodeNext(field: field)
        } catch let error {
            throw EncodingError.invalidValue(value, .writingFailed(field: field, codingPath: self.codingPath, underlyingError: error))
        }
    }
}
