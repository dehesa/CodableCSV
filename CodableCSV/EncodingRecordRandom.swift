import Foundation

extension ShadowEncoder {
    /// Container that will hold a CSV record.
    ///
    /// This container can access its data in random order, such as a dictionary.
    internal final class EncodingRecordRandom<Key:CodingKey>: RecordContainer, EncodingRandomContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        let recordIndex: Int
        
        init(encoder: ShadowEncoder) throws {
            self.recordIndex = try encoder.output.startNextRecord()
            self.codingKey = .record(index: self.recordIndex)
            self.encoder = try encoder.subEncoder(adding: self)
        }
    }
}

extension ShadowEncoder.EncodingRecordRandom {
    func moveBefore(key: Key) throws {
        guard self.recordIndex == self.encoder.output.indices.row else {
            throw EncodingError.invalidValue(Any?.self, .invalidRow(codingPath: self.codingPath))
        }
        
        guard let fieldIndex = key.intValue else {
            throw EncodingError.invalidValue(key, .invalidKey(key, codingPath: self.codingPath))
        }
        
        try self.encoder.output.moveToField(index: fieldIndex)
    }
    
    func encode(field: String, from value: Any, forKey key: Key) throws {
        try self.moveBefore(key: key)
        try self.encoder.output.encodeNext(field: field)
    }
}
