import Foundation

extension ShadowDecoder {
    /// Container holding all CSV records.
    ///
    /// This container only grants access to its data sequentially, such as an array.
    internal final class DecodingFileOrdered: FileDecodingContainer, DecodingOrderedContainer {
        let codingKey: CSVKey = .file
        private(set) var decoder: ShadowDecoder!
        
        init(decoder: ShadowDecoder) throws {
            self.decoder = try decoder.subDecoder(adding: self)
        }
        
        var count: Int? {
            guard self.isAtEnd else { return nil }
            return self.decoder.source.recordsCount
        }
        
        var currentIndex: Int {
            return self.decoder.source.nextRecordIndex
        }
        
        var isAtEnd: Bool {
            return self.decoder.source.isAtEnd
        }
        
        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            return try self.decoder.unkeyedContainer()
        }
        
        func nestedContainer<NestedKey:CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
            return try self.decoder.container(keyedBy: type)
        }
        
        func decodeNil() throws -> Bool {
            guard let row = try self.decoder.source.peakNextRecord(codingPath: self.codingPath) else {
                throw DecodingError.valueNotFound(Any?.self, .isAtEnd(codingPath: self.codingPath))
            }
            
            guard row.count == 1 else {
                throw DecodingError.typeMismatch(Any?.self, .isNotSingleColumn(codingPath: self.codingPath))
            }
            
            guard row.first!.decodeToNil() else { return false }
            try self.moveForward()
            return true
        }
    }
}

extension ShadowDecoder.DecodingFileOrdered {
    func fetchNext(_ type: Any.Type) throws -> String {
        guard let record = try self.decoder.source.fetchRecord(codingPath: self.codingPath) else {
            throw DecodingError.valueNotFound(type, .isAtEnd(codingPath: self.codingPath))
        }
        
        guard record.count == 1 else {
            throw DecodingError.typeMismatch(type, .isNotSingleColumn(codingPath: self.codingPath))
        }
        
        return record.first!
    }
    
    func peakNext() -> String? {
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
}
