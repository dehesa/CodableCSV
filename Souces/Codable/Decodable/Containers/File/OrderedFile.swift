import Foundation

extension ShadowDecoder {
    /// Container holding all CSV records.
    ///
    /// This container only grant access to its data sequential, such as a array.
    internal final class OrderedFile: FileDecodingContainer, OrderedContainer {
        let codingKey: CSV.Key = .file
        private(set) var decoder: ShadowDecoder!
        
        init(decoder: ShadowDecoder) {
            self.decoder = decoder.subDecoder(adding: self)
        }
        
        var count: Int? {
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
        
        func decode<T:Decodable>(_ type: T.Type) throws -> T {
            guard !self.isAtEnd else { throw DecodingError.isAtEnd(type, codingPath: self.codingPath) }
            return try T(from: self.decoder)
        }
        
        func decodeIfPresent<T:Decodable>(_ type: T.Type) throws -> T? {
            guard !self.isAtEnd else { return nil }
            #warning("IDEA: Think on doing roll backs")
            return try T(from: self.decoder)
        }
        
        func decodeNil() throws -> Bool {
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
    }
}

extension ShadowDecoder.OrderedFile {
    func fetchNext(_ type: Any.Type) throws -> String {
        #warning("TODO: Check if the coding path is being formed every single time. Ideally it doesn't execute at all. If not, hardcode it in the initializer")
        guard let record = try self.decoder.source.fetchRecord(codingPath: self.codingPath) else {
            throw DecodingError.isAtEnd(type, codingPath: self.codingPath)
        }
        
        guard record.count == 1 else {
            throw DecodingError.isNotSingleColumn(type, codingPath: self.codingPath)
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
