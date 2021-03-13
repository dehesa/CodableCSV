import Foundation

extension ShadowDecoder {
    /// Unkeyed container for the CSV shadow decoder.
    ///
    /// This container iterates through all the records on a CSV or through all the fields in a single record.
    internal struct UnkeyedContainer: UnkeyedDecodingContainer {
        /// The representation of the decoding process point-in-time.
        private let _decoder: ShadowDecoder
        /// The focus for this container.
        private let _focus: _Focus
        /// Depending on the container's focus, this index represents the next row or the next field to decode.
        private(set) var currentIndex: Int
        
        /// Fast initializer that doesn't perform any checks on the coding path (assuming it is valid).
        /// - parameter decoder: The `Decoder` instance in charge of decoding the CSV data.
        /// - parameter rowIndex: The CSV row targeted for decoding.
        init(unsafeDecoder decoder: ShadowDecoder, rowIndex: Int) {
            self._decoder = decoder
            self._focus = .row(rowIndex)
            self.currentIndex = 0
        }
        
        /// Creates a unkeyed container only if the passed decoder coding path is valid.
        ///
        /// This initializer only allows the creation of a container when the decoder's coding path:
        /// - is empty (implying a unkeyed container traversing the CSV file).
        /// - has a single coding key with an integer value (impliying a unkeyed container traversing a single CSV row).
        init(decoder: ShadowDecoder) throws {
            switch decoder.codingPath.count {
            case 0:
                self._focus = .file
            case 1:
                let key = decoder.codingPath[0]
                let r = try key.intValue ?> CSVDecoder.Error._invalidRowKey(forKey: key, codingPath: decoder.codingPath)
                     self._focus = .row(r)
            default:
                throw CSVDecoder.Error._invalidContainerRequest(codingPath: decoder.codingPath)
            }
            self.currentIndex = 0
            self._decoder = decoder
        }
        
        var codingPath: [CodingKey] {
            self._decoder.codingPath
        }
        
        var count: Int? {
            self._decoder.source._withUnsafeGuaranteedRef { [focus = self._focus] in
                switch focus {
                case .file: return $0.numRows
                case .row: return $0.numExpectedFields
                }
            }
        }
        
        var isAtEnd: Bool {
            self._decoder.source._withUnsafeGuaranteedRef {
                switch self._focus {
                case .file: return (try? $0.isRowAtEnd(index: self.currentIndex)) ?? false
                case .row: return $0.isFieldAtEnd(index: self.currentIndex)
                }
            }
        }
    }
}

extension ShadowDecoder.UnkeyedContainer {
    mutating func nestedContainer<NestedKey:CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        switch self._focus {
        case .file:
            let rowIndex = self.currentIndex
            var codingPath = self._decoder.codingPath; codingPath.append(IndexKey(rowIndex))
            let decoder = ShadowDecoder(source: self._decoder.source, codingPath: codingPath)
            self.currentIndex += 1
            return KeyedDecodingContainer(ShadowDecoder.KeyedContainer(unsafeDecoder: decoder, rowIndex: rowIndex))
        case .row: throw CSVDecoder.Error._invalidContainerRequest(codingPath: self.codingPath)
        }
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        switch self._focus {
        case .file:
            let rowIndex = self.currentIndex
            var codingPath = self._decoder.codingPath; codingPath.append(IndexKey(rowIndex))
            let decoder = ShadowDecoder(source: self._decoder.source, codingPath: codingPath)
            self.currentIndex += 1
            return Self(unsafeDecoder: decoder, rowIndex: rowIndex)
        case .row: throw CSVDecoder.Error._invalidContainerRequest(codingPath: self.codingPath)
        }
    }
    
    mutating func superDecoder() throws -> Decoder {
        switch self._focus {
        case .file:
            var codingPath = self._decoder.codingPath; codingPath.append(IndexKey(self.currentIndex))
            let result = ShadowDecoder(source: self._decoder.source, codingPath: codingPath)
            self.currentIndex += 1
            return result
        case .row: throw CSVDecoder.Error._invalidContainerRequest(codingPath: self.codingPath)
        }
    }
}

extension ShadowDecoder.UnkeyedContainer {
    mutating func decode(_ type: String.Type) throws -> String {
        let result = try self._fieldContainer().decode(String.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decodeNil() throws -> Bool {
        guard try self._fieldContainer().decodeNil() else { return false }
        self.currentIndex += 1
        return true
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        let result = try self._fieldContainer().decode(Bool.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        let result = try self._fieldContainer().decode(Int.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        let result = try self._fieldContainer().decode(Int8.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        let result = try self._fieldContainer().decode(Int16.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        let result = try self._fieldContainer().decode(Int32.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        let result = try self._fieldContainer().decode(Int64.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        let result = try self._fieldContainer().decode(UInt.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        let result = try self._fieldContainer().decode(UInt8.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        let result = try self._fieldContainer().decode(UInt16.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        let result = try self._fieldContainer().decode(UInt32.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        let result = try self._fieldContainer().decode(UInt64.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        let result = try self._fieldContainer().decode(Float.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        let result = try self._fieldContainer().decode(Double.self)
        self.currentIndex += 1
        return result
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T:Decodable {
        let result: T
        
        if T.self == Date.self {
            result = try self._fieldContainer().decode(Date.self) as! T
        } else if T.self == Data.self {
            result = try self._fieldContainer().decode(Data.self) as! T
        } else if T.self == Decimal.self {
            result = try self._fieldContainer().decode(Decimal.self) as! T
        } else if T.self == URL.self {
            result = try self._fieldContainer().decode(URL.self) as! T
        } else {
            var codingPath = self._decoder.codingPath; codingPath.append(IndexKey(self.currentIndex))
            let decoder = ShadowDecoder(source: self._decoder.source, codingPath: codingPath)
            result = try T(from: decoder)
        }
        
        self.currentIndex += 1
        return result
    }
}

// MARK: -

private extension ShadowDecoder.UnkeyedContainer {
    /// CSV unkeyed container focus (i.e. where the container is able to operate on).
    enum _Focus {
        /// The container represents the whole CSV file and each decoding operation outputs a row/record.
        case file
        /// The container represents a CSV row and each decoding operation outputs a field.
        case row(Int)
    }
    
    /// Returns a single value container to decode a single field within a row.
    /// - returns: The single value container holding the field decoding functionality.
    mutating func _fieldContainer() throws -> ShadowDecoder.SingleValueContainer {
        let index: (row: Int, field: Int)
        var codingPath = self._decoder.codingPath
        codingPath.append(IndexKey(self.currentIndex))
        
        switch self._focus {
        case .row(let rowIndex):
            index = (rowIndex, self.currentIndex)
        case .file:
            // Values are only allowed to be decoded directly from a nested container in "file level" if the CSV rows have a single column.
            guard self._decoder.source._withUnsafeGuaranteedRef({ $0.numExpectedFields == 1 }) else { throw CSVDecoder.Error._invalidNestedRequired(codingPath: self.codingPath) }
            index = (self.currentIndex, 0)
            codingPath.append(IndexKey(index.field))
        }
        
        let decoder = ShadowDecoder(source: self._decoder.source, codingPath: codingPath)
        return .init(unsafeDecoder: decoder, rowIndex: index.row, fieldIndex: index.field)
    }
}

fileprivate extension CSVDecoder.Error {
    /// Error raised when a coding key representing a row within the CSV file cannot be transformed into an integer value.
    /// - parameter codingPath: The whole coding path, including the invalid row key.
    static func _invalidRowKey(forKey key: CodingKey, codingPath: [CodingKey]) -> CSVError<CSVDecoder> {
        .init(.invalidPath,
              reason: "The coding key identifying a CSV row couldn't be transformed into an integer value.",
              help: "The provided coding key identifying a CSV row must implement `intValue`.",
              userInfo: ["Coding path": codingPath, "Key": key])
    }
    /// Error raised when a unkeyed container is requested on an invalid coding path.
    /// - parameter codingPath: The full chain of containers which generated this error.
    static func _invalidContainerRequest(codingPath: [CodingKey]) -> CSVError<CSVDecoder> {
        .init(.invalidPath,
              reason: "A CSV doesn't support more than two nested encoding container.",
              help: "Don't ask for a unkeyed decoding container on this coding path.",
              userInfo: ["Coding path": codingPath])
    }
    /// Error raised when a value is decoded, but a container was expected by the decoder.
    static func _invalidNestedRequired(codingPath: [CodingKey]) -> CSVError<CSVDecoder> {
        .init(.invalidPath,
              reason: "A nested container is needed to decode at this coding path.",
              help: "Request a nested container instead of trying to decode a value directly.",
              userInfo: ["Coding path": codingPath])
    }
}
