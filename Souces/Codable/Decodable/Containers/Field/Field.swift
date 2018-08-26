import Foundation

extension ShadowDecoder {
    /// A decoding container holding ont a single field.
    internal final class Field: DecodingContainer, SingleValueDecodingContainer {
        let codingKey: CSV.Key
        private(set) var decoder: ShadowDecoder!
        /// The field value.
        let value: String
        
        init(decoder: ShadowDecoder) throws {
            switch decoder.chain.state {
            case .record(let recordContainer):
                guard case .record(let recordIndex) = recordContainer.codingKey else { fatalError() }
                self.codingKey = CSV.Key.field(index: recordContainer.currentIndex, recordIndex: recordIndex)
                self.value = recordContainer.row[recordContainer.currentIndex]
            case .field(let fieldContainer):
                self.codingKey = fieldContainer.codingKey
                self.value = fieldContainer.value
            default:
                throw DecodingError.invalidContainer(codingPath: decoder.codingPath)
            }
            
            self.decoder = try decoder.subDecoder(adding: self)
        }
        
        func decodeNil() -> Bool {
            return self.value.decodeToNil()
        }
        
        func decode(_ type: Bool.Type) throws -> Bool {
            guard let result = self.value.decodeToBool() else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: String.Type) throws -> String {
            return self.value
        }
        
        func decode(_ type: Double.Type) throws -> Double {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: Float.Type) throws -> Float {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: Int.Type) throws -> Int {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: Int8.Type) throws -> Int8 {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: Int16.Type) throws -> Int16 {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: Int32.Type) throws -> Int32 {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: Int64.Type) throws -> Int64 {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: UInt.Type) throws -> UInt {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: UInt8.Type) throws -> UInt8 {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: UInt16.Type) throws -> UInt16 {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: UInt32.Type) throws -> UInt32 {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode(_ type: UInt64.Type) throws -> UInt64 {
            guard let result = type.init(self.value) else {
                throw DecodingError.mismatchError(string: self.value, codingPath: self.codingPath)
            }
            return result
        }
        
        func decode<T:Decodable>(_ type: T.Type) throws -> T {
            return try T(from: self.decoder)
        }

    }
}
