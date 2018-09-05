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
        
        public func encodeConditional<T>(_ object: T) throws where T: AnyObject & Encodable {
            //#warning("TODO: Conditional encoding is currently unsupported.")
            return try self.encode(object)
        }
        
        public func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            return self.encoder.unkeyedContainer()
        }
        
        public func nestedContainer<NestedKey:CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            return self.encoder.container(keyedBy: keyType)
        }
    }
}

extension ShadowEncoder.EncodingFileOrdered {
    private func canEncodeNextField() -> Bool {
        guard let maxFields = self.encoder.output.maxFieldsPerRecord else {
            return true
        }
        
        return maxFields == 1
    }
    
    func encodeNext(field: String, from value: Any) throws {
        guard canEncodeNextField() else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The unkeyed container representing the CSV file cannot encode single values if CSV rows have more than one column.")
            throw EncodingError.invalidValue(field, context)
        }
        try self.encoder.output.encodeNext(record: [field])
    }
    
    func encodeNext(record: [String], from sequence: Any) throws {
        if let maxFields = self.encoder.output.maxFieldsPerRecord,
           record.count > maxFields {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The given sequence to encode as a CSV rows (i.e. \(record.count)) has more fields than the CSV file is allowed to have (i.e. \(maxFields).")
            throw EncodingError.invalidValue(sequence, context)
        }
        
        try self.encoder.output.encodeNext(record: record)
    }
}
