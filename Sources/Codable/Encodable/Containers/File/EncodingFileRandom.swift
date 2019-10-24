import Foundation

extension ShadowEncoder {
    /// Container which will hold all CSV records.
    ///
    /// This container can access its data in random order, such as a dictionary.
    internal final class EncodingFileRandom<Key:CodingKey>: FileContainer, EncodingRandomContainer {
        let codingKey: CSVKey = .file
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            self.encoder = try encoder.subEncoder(adding: self)
        }
    }
}

extension ShadowEncoder.EncodingFileRandom {
    func moveBefore(key: Key) throws {
        guard let recordIndex = key.intValue else {
            throw EncodingError.invalidValue(key, .invalidKey(key, codingPath: self.codingPath))
        }
        
        try self.encoder.output.moveToRecord(index: recordIndex)
    }
    
    func encode(field: String, from value: Any, forKey key: Key) throws {
        // Encoding single values is only allowed if the CSV is a single column file.
        if let maxFields = self.encoder.output.maxFieldsPerRecord, maxFields != 1 {
            throw EncodingError.invalidValue(field, .isNotSingleColumn(codingPath: self.codingPath))
        }
        
        try self.moveBefore(key: key)
        try self.encoder.output.encodeNext(field: field)
    }
}
