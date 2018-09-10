import Foundation

extension ShadowEncoder {
    /// Container which will hold all CSV records.
    ///
    /// This container only grants access to its data sequentially, such as an array.
    internal final class EncodingFileOrdered: FileContainer, EncodingOrderedContainer {
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
        // Encoding single values is only allowed if the CSV is a single column file.
        if let maxFields = self.encoder.output.maxFieldsPerRecord, maxFields != 1 {
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
        // Encoding multiple values is allowed at file level. The encoder will try to encode a row represented by the parameter `record`.
        do {
            try self.encoder.output.encodeNext(record: record)
        } catch let error {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The record from sequence \(sequence) couldn't be written in the unkeyed container representing the CSV file due to a low-level CSV writer error.", underlyingError: error)
            throw EncodingError.invalidValue(sequence, context)
        }
    }
}
