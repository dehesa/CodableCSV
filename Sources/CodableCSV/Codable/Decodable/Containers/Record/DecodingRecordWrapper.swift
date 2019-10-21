import Foundation

extension ShadowDecoder {
    /// Wraps a CSV record/row in a single value container.
    ///
    /// This container can extract data if the CSV record being pointed to contains a single field.
    internal final class DecodingRecordWrapper: WrapperRecordContainer, DecodingValueContainer, SingleValueDecodingContainer {
        let codingKey: CSVKey
        private(set) var decoder: ShadowDecoder!
        /// The record being targeted.
        let recordIndex: Int

        init(decoder: ShadowDecoder) throws {
            self.codingKey = CSVKey.record(index: decoder.source.nextRecordIndex)
            self.recordIndex = decoder.source.nextRecordIndex
            self.decoder = try decoder.subDecoder(adding: self)
        }

        func decodeNil() -> Bool {
            do {
                guard self.decoder.source.nextRecordIndex == self.recordIndex else {
                    throw DecodingError.valueNotFound(Any?.self, .invalidDataSource(codingPath: self.codingPath))
                }
                
                guard let record = try self.decoder.source.fetchRecord(codingPath: self.codingPath) else {
                    return true
                }
                
                guard record.count <= 1 else { return false  }
                return record.first?.decodeToNil() ?? true
            } catch {
                return false
            }
        }

        func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            guard self.decoder.source.nextRecordIndex == self.recordIndex else {
                throw DecodingError.valueNotFound(type, .invalidDataSource(codingPath: self.codingPath))
            }
            return try T(from: self.decoder)
        }
    }
}

extension ShadowDecoder.DecodingRecordWrapper {
    func fetchNext(_ type: Any.Type) throws -> String {
        guard self.decoder.source.nextRecordIndex == self.recordIndex else {
            throw DecodingError.valueNotFound(type, .invalidDataSource(codingPath: self.codingPath))
        }
        
        guard let record = try self.decoder.source.fetchRecord(codingPath: self.codingPath) else {
            throw DecodingError.valueNotFound(type, .isAtEnd(codingPath: self.codingPath))
        }
        
        guard record.count == 1 else {
            throw DecodingError.typeMismatch(type, .isNotSingleColumn(codingPath: self.codingPath))
        }
        
        return record.first!
    }
}
