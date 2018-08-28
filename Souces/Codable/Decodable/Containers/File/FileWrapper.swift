import Foundation

extension ShadowDecoder {
    /// Wraps a CSV file in a single value container.
    ///
    /// This container can extract data if the CSV file contains a single record and a single value (not counting the header).
    internal final class FileWrapper: WrapperDecodingContainer, SingleValueDecodingContainer {
        let codingKey: CSV.Key = .file
        private(set) var decoder: ShadowDecoder!
        /// The record being targeted.
        let recordIndex: Int
        
        init(decoder: ShadowDecoder) throws {
            self.recordIndex = decoder.source.nextRecordIndex
            self.decoder = try decoder.subDecoder(adding: self)
        }
        
        func decodeNil() -> Bool {
            do {
                guard self.decoder.source.nextRecordIndex == self.recordIndex else {
                    throw DecodingError.invalidDataSource(Any?.self, codingPath: self.codingPath)
                }
                
                guard let value = try self.decoder.source.fetchSingleValueFile(Any?.self, codingPath: self.codingPath) else {
                    return true
                }
                
                return value.decodeToNil()
            } catch {
                return false
            }
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            return try T(from: self.decoder)
        }
    }
}

extension ShadowDecoder.FileWrapper {
    func fetchNext(_ type: Any.Type) throws -> String {
        guard self.decoder.source.nextRecordIndex == self.recordIndex else {
            throw DecodingError.invalidDataSource(type, codingPath: self.codingPath)
        }
        
        guard let field = try self.decoder.source.fetchSingleValueFile(type, codingPath: self.codingPath) else {
            throw DecodingError.isAtEnd(type, codingPath: self.codingPath)
        }
        
        return field
    }
}
