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
        // Encoding single values is only allowed if the CSV is a single column file.
        if let maxFields = self.encoder.output.maxFieldsPerRecord, maxFields != 1 {
            throw EncodingError.invalidValue(field, .isNotSingleColumn(codingPath: self.codingPath))
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
}
