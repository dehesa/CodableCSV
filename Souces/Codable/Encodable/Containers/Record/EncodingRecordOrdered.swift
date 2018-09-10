import Foundation

extension ShadowEncoder {
    /// Container that will hold one CSV record.
    internal final class EncodingRecordOrdered: RecordContainer, EncodingOrderedContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        let recordIndex: Int
        
        init(encoder: ShadowEncoder) throws {
            self.recordIndex = try encoder.output.startNextRecord()
            self.codingKey = .record(index: self.recordIndex)
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
    }
}

extension ShadowEncoder.EncodingRecordOrdered {
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
    
    func encodeNext(record: [String], from sequence: Any) throws {
        // If `record` is empty, encode a nil value.
        guard !record.isEmpty else {
            return try self.encodeNext(field: "", from: record)
        }
        
        unowned let output = self.encoder.output
        
        guard self.recordIndex == output.indices.row else {
            throw EncodingError.invalidValue(sequence, .invalidRow(codingPath: self.codingPath))
        }
        
        do {
            for value in record {
                try output.encodeNext(field: value)
            }
        } catch let error {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The sequence \(sequence) couldn't be writen due to a low-level CSV writer error.", underlyingError: error)
            throw EncodingError.invalidValue(sequence, context)
        }
    }
}
