import Foundation

extension ShadowEncoder {
    /// Container that will hold one CSV record.
    internal final class EncodingRecordOrdered: RecordEncodingContainer, EncodingOrderedContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            let index = try encoder.output.startNextRecord()
            self.codingKey = .record(index: index)
            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        init(encoder: ShadowEncoder, at recordIndex: Int) throws {
            try encoder.output.startRecord(at: recordIndex)
            let index = recordIndex
            self.codingKey = .record(index: index)
            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        public var count: Int {
            return self.encoder.output.fieldsCount
        }
        
        public func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element : Encodable {
            for value in sequence {
                try self.encode(value)
            }
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

extension ShadowEncoder.EncodingRecordOrdered {
    private func canEncodeNextField() -> Bool {
        guard let maxFields = self.encoder.output.maxFieldsPerRecord else {
            return true
        }
        
        return maxFields <= self.encoder.output.fieldsCount + 1
    }
    
    func encodeNext(field: String, from value: Any) throws {
        guard canEncodeNextField() else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "No further fields can be encoded because the maximum number of fields have already been reached.")
            throw EncodingError.invalidValue(field, context)
        }
        
        try self.encoder.output.encodeNext(field: field)
    }
    
    func encodeNext(record: [String], from sequence: Any) throws {
        if let maxFields = self.encoder.output.maxFieldsPerRecord,
           self.count + record.count > maxFields {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The given sequence to encode as a CSV rows (i.e. \(record.count)) has more fields than the CSV file is allowed to have (i.e. \(maxFields).")
            throw EncodingError.invalidValue(sequence, context)
        }
        
        for value in record {
            try self.encoder.output.encodeNext(field: value)
        }
    }
}
