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
        
        public func encodeNil() throws {
            let result = String.nilRepresentation()
            try self.encodeNext(field: result, from: "nil")
        }
        
        public func encode<T:Encodable>(_ value: T) throws {
            #warning("TODO")
            fatalError()
        }
        
        public func encodeConditional<T>(_ object: T) throws where T: AnyObject & Encodable {
            #warning("TODO: Figure out if there is a good way to do this.")
            return try self.encode(object)
        }
        
        public func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element: Encodable {
            #warning("TODO")
            fatalError()
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
    func encodeNext(field: String, from value: Any) throws {
        unowned let output = self.encoder.output
        
        if let maxFields = output.maxFieldsPerRecord, maxFields > 1 {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The unkeyed container representing the CSV file cannot encode single values if CSV rows have more than one column. The current CSV file has \(maxFields) columns.")
            throw EncodingError.invalidValue(field, context)
        }
        
        try output.encodeNext(record: [field])
    }
    
    func encodeNext(record: [String], from sequence: Any) throws {
        unowned let output = self.encoder.output
        
        if let maxFields = output.maxFieldsPerRecord, maxFields > record.count {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The given sequence to encode as a CSV rows (i.e. \(record.count)) has more fields than the CSV file is allowed to have (i.e. \(maxFields).")
            throw EncodingError.invalidValue(sequence, context)
        }
        
        try output.encodeNext(record: record)
    }
}
