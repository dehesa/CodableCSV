import Foundation

extension ShadowDecoder {
    /// Keyed container for the CSV shadow decoder.
    ///
    /// This container lets you randomly access all the CSV rows or all the fields within a single rows.
    internal struct KeyedContainer<Key>: KeyedDecodingContainerProtocol where Key:CodingKey {
        /// The representation of the decoding process point-in-time.
        private let _decoder: ShadowDecoder
        /// The container's target (or level).
        private let _focus: _Focus
        
        /// Fast initializer that doesn't perform any checks on the coding path (assuming it is valid).
        /// - parameter decoder: The `Decoder` instance in charge of decoding the CSV data.
        /// - parameter rowIndex: The CSV row targeted for decoding.
        init(unsafeDecoder decoder: ShadowDecoder, rowIndex: Int) {
            self._decoder = decoder
            self._focus = .row(rowIndex)
        }
        
        /// Creates a keyed container only if the passed decoder's coding path is valid.
        ///
        /// This initializer only allows the creation of a container when the decoder's coding path:
        /// - is empty (implying a keyed container traversing the CSV file),
        /// - has a single coding key with an integer value (implying a keyed container traversing a single CSV row).
        /// - parameter decoder: The `Decoder` instance in charge of decoding the CSV data.
        init(decoder: ShadowDecoder) throws {
            switch decoder.codingPath.count {
            case 0:
                self._focus = .file
            case 1:
                let key = decoder.codingPath[0]
                let r = try key.intValue ?> CSVDecoder.Error._invalidRowKey(forKey: key, codingPath: decoder.codingPath)
                self._focus = .row(r)
            default:
                throw CSVDecoder.Error._invalidContainerRequest(forKey: decoder.codingPath.last!, codingPath: decoder.codingPath)
            }
            self._decoder = decoder
        }
        
        var codingPath: [CodingKey] {
            self._decoder.codingPath
        }
        
        var allKeys: [Key] {
            self._decoder.source._withUnsafeGuaranteedRef { [focus = self._focus] in
                switch focus {
                case .file:
                    guard let numRows = $0.numRows, numRows > 0 else { return [] }
                    return (0..<numRows).compactMap { Key(intValue: $0) }
                case .row:
                    let numFields = $0.numExpectedFields
                    guard numFields > 0 else { return [] }
                    
                    let numberKeys = (0..<numFields).compactMap { Key(intValue: $0) }
                    guard numberKeys.isEmpty else { return numberKeys }
                    
                    return $0.headers.compactMap { Key(stringValue: $0) }
                }
            }
        }
        
        func contains(_ key: Key) -> Bool {
            self._decoder.source._withUnsafeGuaranteedRef { [focus = self._focus] in
                switch focus {
                case .file:
                    guard let index = key.intValue else { return false }
                    return $0.contains(rowIndex: index)
                case .row:
                    if let index = key.intValue {
                        return index >= 0 && index < $0.numExpectedFields
                    } else {
                        return $0.headers.contains(key.stringValue)
                    }
                }
            }
        }
    }
}

extension ShadowDecoder.KeyedContainer {
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        switch self._focus {
        case .file:
            guard let rowIndex = key.intValue else { throw CSVDecoder.Error._invalidRowKey(forKey: key, codingPath: self.codingPath + [key]) }
            var codingPath = self._decoder.codingPath; codingPath.append(IndexKey(rowIndex))
            let decoder = ShadowDecoder(source: self._decoder.source, codingPath: codingPath)
            return KeyedDecodingContainer(ShadowDecoder.KeyedContainer<NestedKey>(unsafeDecoder: decoder, rowIndex: rowIndex))
        case .row: throw CSVDecoder.Error._invalidContainerRequest(forKey: key, codingPath: self.codingPath)
        }
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        switch self._focus {
        case .file:
            guard let rowIndex = key.intValue else { throw CSVDecoder.Error._invalidRowKey(forKey: key, codingPath: self.codingPath + [key]) }
            var codingPath = self._decoder.codingPath; codingPath.append(IndexKey(rowIndex))
            let decoder = ShadowDecoder(source: self._decoder.source, codingPath: codingPath)
            return ShadowDecoder.UnkeyedContainer(unsafeDecoder: decoder, rowIndex: rowIndex)
        case .row: throw CSVDecoder.Error._invalidContainerRequest(forKey: key, codingPath: self.codingPath)
        }
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        switch self._focus {
        case .file:
            guard let rowIndex = key.intValue else { throw CSVDecoder.Error._invalidRowKey(forKey: key, codingPath: self.codingPath + [key]) }
            var codingPath = self._decoder.codingPath; codingPath.append(IndexKey(rowIndex))
            return ShadowDecoder(source: self._decoder.source, codingPath: codingPath)
        case .row: throw CSVDecoder.Error._invalidContainerRequest(forKey: key, codingPath: self.codingPath)
        }
    }
    
    func superDecoder() throws -> Decoder {
        switch self._focus {
        case .file:
            var codingPath = self._decoder.codingPath; codingPath.append(IndexKey(0))
            return ShadowDecoder(source: self._decoder.source, codingPath: codingPath)
        case .row: throw CSVDecoder.Error._invalidContainerRequest(forKey: NameKey(index: 0, name: "super"), codingPath: self.codingPath)
        }
    }
}

extension ShadowDecoder.KeyedContainer {
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        try self._fieldContainer(forKey: key).decode(String.self)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        try self._fieldContainer(forKey: key).decodeNil()
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        try self._fieldContainer(forKey: key).decode(Bool.self)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        try self._fieldContainer(forKey: key).decode(Int.self)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        try self._fieldContainer(forKey: key).decode(Int8.self)
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        try self._fieldContainer(forKey: key).decode(Int16.self)
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        try self._fieldContainer(forKey: key).decode(Int32.self)
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        try self._fieldContainer(forKey: key).decode(Int64.self)
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        try self._fieldContainer(forKey: key).decode(UInt.self)
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        try self._fieldContainer(forKey: key).decode(UInt8.self)
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        try self._fieldContainer(forKey: key).decode(UInt16.self)
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        try self._fieldContainer(forKey: key).decode(UInt32.self)
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        try self._fieldContainer(forKey: key).decode(UInt64.self)
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        try self._fieldContainer(forKey: key).decode(Float.self)
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        try self._fieldContainer(forKey: key).decode(Double.self)
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T:Decodable {
        if T.self == Date.self {
            return try self._fieldContainer(forKey: key).decode(Date.self) as! T
        } else if T.self == Data.self {
            return try self._fieldContainer(forKey: key).decode(Data.self) as! T
        } else if T.self == Decimal.self {
            return try self._fieldContainer(forKey: key).decode(Decimal.self) as! T
        } else if T.self == URL.self {
            return try self._fieldContainer(forKey: key).decode(URL.self) as! T
        } else {
            var codingPath = self._decoder.codingPath; codingPath.append(key)
            return try T(from: ShadowDecoder(source: self._decoder.source, codingPath: codingPath))
        }
    }
}

//extension ShadowDecoder.KeyedContainer {
//    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
//        try? self.decode(String.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
//        try? self.decode(Bool.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
//        try? self.decode(Int.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
//        try? self.decode(Int8.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
//        try? self.decode(Int16.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
//        try? self.decode(Int32.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
//        try? self.decode(Int64.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
//        try? self.decode(UInt.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
//        try? self.decode(UInt8.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
//        try? self.decode(UInt16.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
//        try? self.decode(UInt32.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
//        try? self.decode(UInt64.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
//        try? self.decode(Float.self, forKey: key)
//    }
//
//    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
//        try? self.decode(Double.self, forKey: key)
//    }
//
//    func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T:Decodable {
//        try? self.decode(T.self, forKey: key)
//    }
//}

// MARK: -

private extension ShadowDecoder.KeyedContainer {
    /// CSV keyed container focus (i.e. where the container is able to operate on).
    enum _Focus {
        /// The container represents the whole CSV file and each decoding operation outputs a row/record.
        case file
        /// The container represents a CSV row and each decoding operation outputs a field.
        case row(Int)
    }
    
    /// Returns a single value container to decode a single field within a row.
    /// - parameter key: The coding key under which the `String` value is located.
    /// - returns: The single value container holding the field decoding functionality.
    func _fieldContainer(forKey key: Key) throws -> ShadowDecoder.SingleValueContainer {
        let index: (row: Int, field: Int)
        var codingPath = self._decoder.codingPath
        codingPath.append(key)
        
        switch self._focus {
        case .row(let rowIndex):
            index = (rowIndex, try self._decoder.source._withUnsafeGuaranteedRef { try $0.fieldIndex(forKey: key, codingPath: self.codingPath) })
        case .file:
            guard let rowIndex = key.intValue else { throw CSVDecoder.Error._invalidRowKey(forKey: key, codingPath: codingPath) }
            // Values are only allowed to be decoded directly from a nested container in "file level" if the CSV rows have a single column.
            guard self._decoder.source._withUnsafeGuaranteedRef({ $0.numExpectedFields == 1 }) else { throw CSVDecoder.Error._invalidNestedRequired(codingPath: self.codingPath) }
            index = (rowIndex, 0)
            codingPath.append(IndexKey(index.field))
        }
        
        let decoder = ShadowDecoder(source: self._decoder.source, codingPath: codingPath)
        return .init(unsafeDecoder: decoder, rowIndex: index.row, fieldIndex: index.field)
    }
}

fileprivate extension CSVDecoder.Error {
    /// Error raised when a coding key representing a row within the CSV file cannot be transformed into an integer value.
    /// - parameter codingPath: The full decoding chain.
    static func _invalidRowKey(forKey key: CodingKey, codingPath: [CodingKey]) -> CSVError<CSVDecoder> {
        .init(.invalidPath,
              reason: "The coding key identifying a CSV row couldn't be transformed into an integer value.",
              help: "The provided coding key identifying a CSV row must implement `intValue`.",
              userInfo: ["Coding path": codingPath, "Key": key])
    }
    /// Error raised when a keyed container is requested on an invalid coding path.
    /// - parameter codingPath: The full decoding chain.
    static func _invalidContainerRequest(forKey key: CodingKey, codingPath: [CodingKey]) -> CSVError<CSVDecoder> {
        .init(.invalidPath,
              reason: "A CSV doesn't support more than two nested decoding container.",
              help: "Don't ask for a nested container on the targeted key for this coding path.",
              userInfo: ["Coding path": codingPath, "Key": key])
    }
    /// Error raised when a value is decoded, but a container was expected by the decoder.
    /// - parameter codingPath: The full decoding chain.
    static func _invalidNestedRequired(codingPath: [CodingKey]) -> CSVError<CSVDecoder> {
        .init(.invalidPath,
              reason: "A nested container is needed to decode CSV row values",
              help: "Request a nested container instead of trying to decode a value directly.",
              userInfo: ["Coding path": codingPath])
    }
}
