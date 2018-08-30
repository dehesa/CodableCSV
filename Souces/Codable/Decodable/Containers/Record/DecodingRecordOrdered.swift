import Foundation

extension ShadowDecoder {
    /// Container holding one CSV record
    internal final class DecodingRecordOrdered: RecordDecodingContainer, DecodingOrderedContainer {
        let codingKey: CSV.Key
        private(set) var decoder: ShadowDecoder!
        
        let record: [String]
        let recordIndex: Int
        var currentIndex: Int
        
        init(decoder: ShadowDecoder) throws {
            self.recordIndex = decoder.source.nextRecordIndex
            self.codingKey = CSV.Key.record(index: self.recordIndex)
            
            guard let row = try decoder.source.fetchRecord(codingPath: decoder.codingPath) else {
                throw DecodingError.isAtEnd(DecodingRecordOrdered.self, codingPath: decoder.codingPath)
            }
            self.record = row
            self.currentIndex = 0
            
            self.decoder = try decoder.subDecoder(adding: self)
        }
        
        var count: Int? {
            return self.record.count
        }
        
        var isAtEnd: Bool {
            return self.currentIndex >= self.record.endIndex
        }
        
        func nestedContainer<NestedKey:CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
            throw DecodingError.invalidNestedContainer(Any.self, codingPath: self.codingPath)
        }
        
        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            throw DecodingError.invalidNestedContainer(Any.self, codingPath: self.codingPath)
        }
        
        func decodeNil() throws -> Bool {
            guard !self.isAtEnd else {
                throw DecodingError.isAtEnd(Any?.self, codingPath: self.codingPath)
            }
            
            guard self.record[self.currentIndex].decodeToNil() else { return false }
            self.moveForward()
            return true
        }
    }
}

extension ShadowDecoder.DecodingRecordOrdered {
    func fetchNext(_ type: Any.Type) throws -> String {
        guard !self.isAtEnd else {
            throw DecodingError.isAtEnd(type, codingPath: self.codingPath)
        }
        
        let field = self.record[self.currentIndex]
        self.moveForward()
        return field
    }
    
    func peakNext() -> String? {
        guard !self.isAtEnd else { return nil }
        return self.record[self.currentIndex]
    }
    
    func moveForward() {
        self.currentIndex += 1
    }
}
