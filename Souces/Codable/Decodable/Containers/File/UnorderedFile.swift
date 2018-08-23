import Foundation

extension ShadowDecoder {
    /// Container holding all CSV records.
    ///
    /// This container can access its data in random order, such as a dictionary.
    internal final class UnorderedFile<Key:CodingKey>: FileDecodingContainer, UnorderedContainer {
        let codingKey: CSV.Key = .file
        private(set) var decoder: ShadowDecoder!
        
        init(decoder: ShadowDecoder) throws {
            self.decoder = try decoder.subDecoder(adding: self)
        }
        
        var allKeys: [Key] {
            guard !self.decoder.source.isAtEnd,
                let key = Key(intValue: self.decoder.source.nextRecordIndex) else {
                    return .init()
            }
            return [key]
        }
        
        func contains(_ key: Key) -> Bool {
            guard let index = key.intValue else { return false }
            
            if let count = self.decoder.source.recordsCount {
                return index < count
            }
            
            return index <= self.decoder.source.nextRecordIndex
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            try self.moveBefore(key: key)
            return try self.decoder.unkeyedContainer()
        }
        
        func nestedContainer<NestedKey:CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
            try self.moveBefore(key: key)
            return try self.decoder.container(keyedBy: type)
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            try self.moveBefore(key: key)
            return try T(from: self.decoder)
        }
        
        func decodeIfPresent<T:Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
            try self.moveBefore(key: key)
            return try T(from: self.decoder)
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            try self.moveBefore(key: key)
            
            guard let row = try self.decoder.source.peakNextRecord(codingPath: self.codingPath) else {
                throw DecodingError.isAtEnd(Any?.self, codingPath: self.codingPath)
            }
            
            guard row.count == 1 else {
                throw DecodingError.isNotSingleColumn(Any?.self, codingPath: self.codingPath)
            }
            
            guard row.first!.decodeToNil() else { return false }
            try self.moveForward()
            return true
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            try self.moveBefore(key: key)
            return self.decoder.superDecoder()
        }
    }
}

extension ShadowDecoder.UnorderedFile {
    func fetch(_ type: Any.Type, forKey key: Key) throws -> String {
        try moveBefore(key: key)
        
        guard let record = try self.decoder.source.fetchRecord(codingPath: self.codingPath) else {
            throw DecodingError.isAtEnd(type, codingPath: self.codingPath)
        }
        
        guard record.count == 1 else {
            throw DecodingError.isNotSingleColumn(type, codingPath: self.codingPath)
        }
        
        return record.first!
    }
    
    func peak(_ type: Any.Type, forKey key: Key) throws -> String? {
        guard let index = key.intValue else {
            throw DecodingError.invalidDecodingKey(key: key, codingPath: self.codingPath)
        }
        
        guard try self.decoder.source.moveBeforeRecord(index: index, codingKey: key, codingPath: self.codingPath) else {
            return nil
        }
        
        let row: [String]?
        do {
            row = try self.decoder.source.peakNextRecord(codingPath: self.codingPath)
        } catch {
            return nil
        }
        
        guard let record = row, record.count == 1 else { return nil }
        return record.first!
    }
    
    func moveForward() throws {
        let _ = try self.decoder.source.fetchRecord(codingPath: self.codingPath)
    }
    
    fileprivate func moveBefore(key: Key) throws {
        guard let index = key.intValue else {
            throw DecodingError.invalidDecodingKey(key: key, codingPath: self.codingPath)
        }
        
        guard try self.decoder.source.moveBeforeRecord(index: index, codingKey: key, codingPath: self.codingPath) else {
            throw DecodingError.invalidDecodingKey(key: codingKey, codingPath: self.codingPath)
            
        }
    }
}
