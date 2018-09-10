import Foundation

extension ShadowEncoder {
    /// Wraps a CSV file in a single value container.
    ///
    /// This container can encode data if the CSV file contains a single record and a single value (not counting the header).
    internal final class EncodingFileWrapper: WrapperFileContainer, EncodingValueContainer, SingleValueEncodingContainer {
        let codingKey: CSVKey = .file
        private(set) var encoder: ShadowEncoder!
        /// The record being targeted.
        let recordIndex: Int
        
        init(encoder: ShadowEncoder) throws {
            self.recordIndex = encoder.output.indices.row
            self.encoder = try encoder.subEncoder(adding: self)
        }
    }
}

extension ShadowEncoder.EncodingFileWrapper {
    func encodeNext(field: String, from value: Any) throws {
        guard canEncodeNextField() else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The container representing the CSV file cannot encode single values if CSV rows have more than one column.")
            throw EncodingError.invalidValue(field, context)
        }
        
        guard self.recordIndex == self.encoder.output.indices.row else {
            throw EncodingError.invalidValue(value, .invalidRow(codingPath: self.codingPath))
        }
        
        do {
            try self.encoder.output.encodeNext(record: [field])
        } catch let error {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The field \(value) couldn't be written in the container representing the CSV file due to a low-level CSV writer error.", underlyingError: error)
            throw EncodingError.invalidValue(value, context)
        }
    }
    
    /// Returns a Boolean indicating whether a new field can be encoded in the receiving container.
    ///
    /// For file containers, only if the CSV has one column can a field be encoded.
    private func canEncodeNextField() -> Bool {
        guard let maxFields = self.encoder.output.maxFieldsPerRecord else {
            return true
        }
        
        return maxFields == 1
    }
}
