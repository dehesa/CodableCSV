import Foundation

extension ShadowEncoder {
    /// Container that will hold a CSV record.
    ///
    /// This container can access its data in random order, such as a dictionary.
    internal final class EncodingRecordRandom<Key:CodingKey>: RecordEncodingContainer, EncodingRandomContainer {
        let recordIndex: Int
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            self.recordIndex = try encoder.output.startNextRecord()
            self.codingKey = .record(index: recordIndex)
            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        /// - throws: `EncodingError` exclusively.
        init(encoder: ShadowEncoder, at recordIndex: Int) throws {
            try encoder.output.startRecord(at: recordIndex)
            self.recordIndex = recordIndex
            self.codingKey = .record(index: recordIndex)
            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return self.superEncoder()
        }
    }
}

extension ShadowEncoder.EncodingRecordRandom {
    func moveBefore(key: Key) throws {
        unowned let output = self.encoder.output
        
        guard self.recordIndex == output.indices.row else {
            throw EncodingError.invalidRow(value: Any?.self, codingPath: self.codingPath)
        }
        
        #warning("TODO")
        fatalError()
    }
    
    func encode(field: String, from value: Any, forKey key: Key) throws {
        unowned let output = self.encoder.output
        
        guard self.recordIndex == output.indices.row else {
            throw EncodingError.invalidRow(value: value, codingPath: self.codingPath)
        }
        
        #warning("TODO")
        fatalError()
    }
}
