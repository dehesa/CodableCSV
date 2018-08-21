import Foundation

extension ShadowDecoder {
    /// Container holding one CSV record
    internal final class OrderedRow: RecordDecodingContainer {
        let codingKey: CodingKey
        private(set) var decoder: ShadowDecoder!
        /// The already parsed CSV row.
        private let row: [String]
        /// The index of the next element to be decoded. Incremented after every successful decode call.
        var currentIndex: Int
        
        init(superDecoder decoder: ShadowDecoder) throws {
            self.codingKey = CSV.Key.record(index: decoder.source.nextRecordIndex)
            
            guard let row = try decoder.source.fetchRecord(codingPath: decoder.codingPath) else {
                throw DecodingError.isAtEnd(OrderedRow.self, codingPath: decoder.codingPath)
            }
            self.row = row
            self.currentIndex = 0
            
            self.decoder = decoder.subDecoder(adding: self)
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
        
        func decode<T:Decodable>(_ type: T.Type) throws -> T {
            guard !self.isAtEnd else { throw DecodingError.isAtEnd(type, codingPath: self.codingPath) }
            #warning("TODO: Check whether I have to go to the next index here or not")
            return try T(from: self.decoder)
        }

        func decodeIfPresent<T:Decodable>(_ type: T.Type) throws -> T? {
            guard !self.isAtEnd else { return nil }
            #warning("TODO: Figure it out")
            return try T(from: self.decoder)
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

extension ShadowDecoder.OrderedRow: OrderedContainer {
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
