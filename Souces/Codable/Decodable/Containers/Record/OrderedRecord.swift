import Foundation

extension ShadowDecoder {
    /// Container holding one CSV record
    internal final class OrderedRecord: RecordDecodingContainer, OrderedContainer {
        let codingKey: CSV.Key
        private(set) var decoder: ShadowDecoder!
        let row: [String]
        private(set) var currentIndex: Int
        
        init(decoder: ShadowDecoder) throws {
            #warning("TODO: This might not be correct. Same problem with SingleValueContainer when decoding from a keyedContainer")
            self.codingKey = CSV.Key.record(index: decoder.source.nextRecordIndex)
            
            guard let row = try decoder.source.fetchRecord(codingPath: decoder.codingPath) else {
                throw DecodingError.isAtEnd(OrderedRecord.self, codingPath: decoder.codingPath)
            }
            self.row = row
            self.currentIndex = 0
            
            self.decoder = try decoder.subDecoder(adding: self)
        }
        
        var count: Int? {
            return self.row.count
        }
        
        var isAtEnd: Bool {
            return self.currentIndex >= self.row.endIndex
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
            
            guard self.row[self.currentIndex].decodeToNil() else { return false }
            self.moveForward()
            return true
        }
    }
}

extension ShadowDecoder.OrderedRecord {
    func fetchNext(_ type: Any.Type) throws -> String {
        guard !self.isAtEnd else {
            throw DecodingError.isAtEnd(type, codingPath: self.codingPath)
        }
        
        let field = self.row[self.currentIndex]
        self.moveForward()
        return field
    }
    
    func peakNext() -> String? {
        guard !self.isAtEnd else { return nil }
        return self.row[self.currentIndex]
    }
    
    func moveForward() {
        self.currentIndex += 1
    }
}
