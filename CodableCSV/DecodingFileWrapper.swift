import Foundation

extension ShadowDecoder {
    /// Wraps a CSV file in a single value container.
    ///
    /// This container can extract data if the CSV file contains a single record and a single value (not counting the header).
    internal final class DecodingFileWrapper: WrapperFileContainer, DecodingValueContainer, SingleValueDecodingContainer {
        let codingKey: CSVKey = .file
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
                    throw DecodingError.valueNotFound(Any?.self, .invalidDataSource(codingPath: self.codingPath))
                }
                
                guard let value = try self.decoder.source.fetchSingleValueFile(Any?.self, codingPath: self.codingPath) else {
                    return true
                }
                
                return value.decodeToNil()
            } catch {
                return false
            }
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            return try T(from: self.decoder)
        }
    }
}

extension ShadowDecoder.DecodingFileWrapper {
    func fetchNext(_ type: Any.Type) throws -> String {
        guard self.decoder.source.nextRecordIndex == self.recordIndex else {
            throw DecodingError.valueNotFound(type, .invalidDataSource(codingPath: self.codingPath))
        }
        
        guard let field = try self.decoder.source.fetchSingleValueFile(type, codingPath: self.codingPath) else {
            throw DecodingError.valueNotFound(type, .isAtEnd(codingPath: self.codingPath))
        }
        
        return field
    }
}
