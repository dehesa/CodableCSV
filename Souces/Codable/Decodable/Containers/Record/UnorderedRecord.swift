import Foundation

extension ShadowDecoder {
    internal final class UnorderedRecord<Key:CodingKey>: RecordDecodingContainer, UnorderedContainer {
        let codingKey: CSV.Key
        private(set) var decoder: ShadowDecoder!
        
        let record: [String]
        let recordIndex: Int
        var currentIndex: Int

        init(decoder: ShadowDecoder) throws {
            self.recordIndex = decoder.source.nextRecordIndex
            self.codingKey = CSV.Key.record(index: self.recordIndex)
            
            guard let row = try decoder.source.fetchRecord(codingPath: decoder.codingPath) else {
                throw DecodingError.isAtEnd(OrderedRecord.self, codingPath: decoder.codingPath)
            }
            self.record = row
            self.currentIndex = 0
            
            self.decoder = try decoder.subDecoder(adding: self)
        }

        var allKeys: [Key] {
            if let header = self.decoder.source.header {
                return zip(header, self.record).enumerated().compactMap { (index, value: (header: String, _: String)) in
                    Key(intValue: index) ?? Key(stringValue: value.header)
                }
            } else {
                return self.record.enumerated().compactMap { (index, _) in
                    Key(intValue: index)
                }
            }
        }

        func contains(_ key: Key) -> Bool {
            return self.indexFor(key: key) != nil
        }

        func nestedContainer<NestedKey:CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
            throw DecodingError.invalidNestedContainer(Any.self, codingPath: self.codingPath)
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            throw DecodingError.invalidNestedContainer(Any.self, codingPath: self.codingPath)
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            guard let value = self.peak(Any?.self, forKey: key) else { return false }
            return value.decodeToNil()
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            try self.moveBefore(key: key)
            return self.decoder.superDecoder()
        }
    }
}

extension ShadowDecoder.UnorderedRecord {
    func fetch(_ type: Any.Type, forKey key: Key) throws -> String {
        try self.moveBefore(key: key)
        let result = self.record[self.currentIndex]
        self.moveForward()
        return result
    }
    
    func peak(_ type: Any.Type, forKey key: Key) -> String? {
        guard let index = self.indexFor(key: key) else { return nil }
        self.currentIndex = index
        return self.record[index]
    }
    
    func moveForward() {
        self.currentIndex += 1
    }
    
    func moveBefore(key: Key) throws {
        guard let index = self.indexFor(key: key) else {
            throw DecodingError.invalidDecodingKey(key: key, codingPath: self.codingPath)
        }
        
        self.currentIndex = index
    }
    
    /// Returns the `self.row` index for the key in the argument.
    ///
    /// It tries to transform the key into an `Int` and if it is not successful, it will try to transform the key into a `String` to match with the header record. If that is the case, the header record length is matched with the stored row length.
    fileprivate func indexFor(key: Key) -> Int? {
        if let index = key.intValue {
            return index
        } else if let headers = self.decoder.source.header {
            let name = key.stringValue
            for (index, headerName) in headers.enumerated() where headerName == name {
                guard index < self.record.endIndex else { return nil }
                return index
            }
        }
        
        return nil
    }
}
