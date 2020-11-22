import Foundation

internal extension ShadowEncoder {
    /// Keyed container for the CSV shadow encoder.
    ///
    /// This container lets you randomly write CSV rows or specific fields within a single row.
    struct KeyedContainer<Key>: KeyedEncodingContainerProtocol where Key:CodingKey {
        /// The representation of the encoding process point-in-time.
        private let _encoder: ShadowEncoder
        /// The focus for this container.
        private let _focus: _Focus
        
        /// Fast initializer that doesn't perform any checks on the coding path (assuming it is valid).
        /// - parameter encoder: The `Encoder` instance in charge of encoding CSV data.
        /// - parameter rowIndex: The CSV row targeted for encoding.
        init(unsafeEncoder encoder: ShadowEncoder, rowIndex: Int) {
            self._encoder = encoder
            self._focus = .row(rowIndex)
        }
        
        /// Creates a keyed container only if the passed encoder's coding path is valid.
        /// - parameter encoder: The `Encoder` instance in charge of encoding CSV data.
        init(encoder: ShadowEncoder) throws {
            switch encoder.codingPath.count {
            case 0:
                self._focus = .file
            case 1:
                let key = encoder.codingPath[0]
                let row = try key.intValue ?> CSVEncoder.Error._invalidRowKey(forKey: key, codingPath: encoder.codingPath)
                self._focus = .row(row)
            default:
                throw CSVEncoder.Error._invalidContainerRequest(forKey: encoder.codingPath.last!, codingPath: encoder.codingPath)
            }
            self._encoder = encoder
        }
        
        var codingPath: [CodingKey] {
            self._encoder.codingPath
        }
    }
}

extension ShadowEncoder.KeyedContainer {
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey:CodingKey {
        var codingPath = self._encoder.codingPath
        codingPath.append(key)
        
        switch (self._focus, key.intValue) {
        case (.file, let rowIndex?):
            let encoder = ShadowEncoder(sink: self._encoder.sink, codingPath: codingPath)
            let container = ShadowEncoder.KeyedContainer<NestedKey>(unsafeEncoder: encoder, rowIndex: rowIndex)
            return KeyedEncodingContainer(container)
        case (.file, .none):
            let error = CSVEncoder.Error._invalidRowKey(forKey: key, codingPath: codingPath)
            return KeyedEncodingContainer(ShadowEncoder.InvalidContainer<NestedKey>(error: error, encoder: self._encoder))
        case (.row, _):
            let error = CSVEncoder.Error._invalidContainerRequest(forKey: key, codingPath: codingPath)
            return KeyedEncodingContainer(ShadowEncoder.InvalidContainer<NestedKey>(error: error, encoder: self._encoder))
        }
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        var codingPath = self._encoder.codingPath
        codingPath.append(key)
        
        switch (self._focus, key.intValue) {
        case (.file, let rowIndex?):
            let encoder = ShadowEncoder(sink: self._encoder.sink, codingPath: codingPath)
            return ShadowEncoder.UnkeyedContainer(unsafeEncoder: encoder, rowIndex: rowIndex)
        case (.file, .none):
            let error = CSVEncoder.Error._invalidRowKey(forKey: key, codingPath: codingPath)
            return ShadowEncoder.InvalidContainer<InvalidKey>(error: error, encoder: self._encoder)
        case (.row, _):
            let error = CSVEncoder.Error._invalidContainerRequest(forKey: key, codingPath: codingPath)
            return ShadowEncoder.InvalidContainer<InvalidKey>(error: error, encoder: self._encoder)
        }
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        var codingPath = self._encoder.codingPath
        codingPath.append(key)
        return ShadowEncoder(sink: self._encoder.sink, codingPath: codingPath)
    }
    
    mutating func superEncoder() -> Encoder {
        var codingPath: [CodingKey] = self.codingPath
        codingPath.append(NameKey(index: 0, name: "super"))
        return ShadowEncoder(sink: self._encoder.sink, codingPath: codingPath)
    }
}

extension ShadowEncoder.KeyedContainer {
    mutating func encode(_ value: String, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encodeNil(forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encodeNil()
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        try container.encode(value)
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T:Encodable {
        switch value {
        case let date as Date:
            var container = try self._fieldContainer(forKey: key)
            try container.encode(date)
        case let data as Data:
            var container = try self._fieldContainer(forKey: key)
            try container.encode(data)
        case let num as Decimal:
            var container = try self._fieldContainer(forKey: key)
            try container.encode(num)
        case let url as URL:
            try self._fieldContainer(forKey: key).encode(url)
        default:
            var codingPath = self._encoder.codingPath
            codingPath.append(key)
            
            let encoder = ShadowEncoder(sink: self._encoder.sink, codingPath: codingPath)
            try value.encode(to: encoder)
        }
    }
    
//    mutating func encodeConditional<T>(_ object: T, forKey key: Key) throws where T:AnyObject, T:Encodable {
//        fatalError()
//    }
}

extension ShadowEncoder.KeyedContainer {
    mutating func encodeIfPresent(_ value: String?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }

    mutating func encodeIfPresent<T>(_ value: T?, forKey key: Key) throws where T:Encodable {
        var container = try self._fieldContainer(forKey: key)
        guard let value = value else { return try container.encodeNil() }
        try container.encode(value)
    }
}

// MARK: -

private extension ShadowEncoder.KeyedContainer {
    /// CSV keyed container focus (i.e. where the container is able to operate on).
    enum _Focus {
        /// The container represents the whole CSV file and each encoding operation writes a row/record.
        case file
        /// The container represents a CSV row and each encoding operation outputs a field.
        case row(Int)
    }
    
    /// Returns a single value container to encode a single field within a row.
    /// - parameter key: The coding key under which the value will be encoded.
    /// - returns: The single value container with the field encoding functionality.
    func _fieldContainer(forKey key: Key) throws -> ShadowEncoder.SingleValueContainer {
        let index: (row: Int, field: Int)
        var codingPath = self._encoder.codingPath
        codingPath.append(key)
        
        switch self._focus {
        case .row(let rowIndex):
            index = (rowIndex, try self._encoder.sink._withUnsafeGuaranteedRef({ try $0.fieldIndex(forKey: key, codingPath: self.codingPath) }))
        case .file:
            guard let rowIndex = key.intValue else { throw CSVEncoder.Error._invalidRowKey(forKey: key, codingPath: codingPath) }
            // Values are only allowed to be decoded directly from a nested container in "file level" if the CSV rows have a single column.
            guard self._encoder.sink._withUnsafeGuaranteedRef({ $0.numExpectedFields == 1 }) else { throw CSVEncoder.Error._invalidNestedRequired(codingPath: codingPath) }
            index = (rowIndex, 0)
            codingPath.append(IndexKey(index.field))
        }
        
        let encoder = ShadowEncoder(sink: self._encoder.sink, codingPath: codingPath)
        return .init(unsafeEncoder: encoder, rowIndex: index.row, fieldIndex: index.field)
    }
}

fileprivate extension CSVEncoder.Error {
    /// Error raised when a coding key representing a row within the CSV file cannot be transformed into an integer value.
    /// - parameter codingPath: The whole coding path, including the invalid row key.
    static func _invalidRowKey(forKey key: CodingKey, codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidPath,
              reason: "The coding key identifying a CSV row couldn't be transformed into an integer value.",
              help: "The provided coding key identifying a CSV row must implement `intValue`.",
              userInfo: ["Coding path": codingPath, "Key": key])
    }
    /// Error raised when a keyed value container is requested on an invalid coding path.
    /// - parameter key: The key on the coding path at which a nested container was requested (but it is not supported by the encoder).
    /// - parameter codingPath: The full encoding chain.
    static func _invalidContainerRequest(forKey key: CodingKey, codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidPath,
              reason: "A CSV doesn't support more than two nested encoding container.",
              help: "Don't ask for a nested container on the targeted key for this coding path.",
              userInfo: ["Coding path": codingPath, "Key": key])
    }
    /// Error raised when a value is encoded, but a container was expected by the encoder.
    /// - parameter codingPath: The full encoding chain.
    static func _invalidNestedRequired(codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidPath,
              reason: "A nested container is needed to encode at this coding path.",
              help: "Request a nested container instead of trying to decode a value directly.",
              userInfo: ["Coding path": codingPath])
    }
}
