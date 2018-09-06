import Foundation

extension ShadowEncoder {
    /// Container which will hold all CSV records.
    ///
    /// This container only grants access to its data sequentially, such as an array.
    internal final class EncodingFileOrdered: FileEncodingContainer, EncodingOrderedContainer {
        let codingKey: CSVKey = .file
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        public var count: Int {
            return self.encoder.output.recordsCount
        }
        
        public func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element: Encodable {
            var record = self.nestedUnkeyedContainer()
            try record.encode(contentsOf: sequence)
        }
    }
}

extension ShadowEncoder.EncodingFileOrdered {
    func encodeNext(field: String, from value: Any) throws {
        guard canEncodeNextField() else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The unkeyed container representing the CSV file cannot encode single values if CSV rows have more than one column.")
            throw EncodingError.invalidValue(field, context)
        }
        
        do {
            try self.encoder.output.encodeNext(record: [field])
        } catch let error {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The field \(value) couldn't be written in the unkeyed container representing the CSV file due to a low-level CSV writer error.", underlyingError: error)
            throw EncodingError.invalidValue(value, context)
        }
    }
    
    func encodeNext(record: [String], from sequence: Any) throws {
        do {
            try self.encoder.output.encodeNext(record: record)
        } catch let error {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The record from sequence \(sequence) couldn't be written in the unkeyed container representing the CSV file due to a low-level CSV writer error.", underlyingError: error)
            throw EncodingError.invalidValue(sequence, context)
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
