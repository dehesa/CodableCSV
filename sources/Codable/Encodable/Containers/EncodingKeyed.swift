import Foundation

extension ShadowEncoder {
    /// Keyed container for the CSV shadow encoder.
    ///
    /// This container lets you randomly write CSV rows or specific fields within a single row.
    struct KeyedContainer<Key>: KeyedEncodingContainerProtocol where Key:CodingKey {
        /// The representation of the encoding process point-in-time.
        private let encoder: ShadowEncoder
        /// The focus for this container.
        private let focus: Focus
        
        /// Fast initializer that doesn't perform any checks on the coding path (assuming it is valid).
        /// - parameter encoder: The `Encoder` instance in charge of encoding CSV data.
        /// - parameter rowIndex: The CSV row targeted for encoding.
        init(unsafeEncoder encoder: ShadowEncoder, rowIndex: Int) {
            self.encoder = encoder
            self.focus = .row(rowIndex)
        }
        
        /// Creates a keyed container only if the passed encoder's coding path is valid.
        /// - parameter encoder: The `Encoder` instance in charge of encoding CSV data.
        init(encoder: ShadowEncoder) throws {
            switch encoder.codingPath.count {
            case 0:
                self.focus = .file
            case 1:
                let key = encoder.codingPath[0]
                let r = try key.intValue ?! CSVEncoder.Error.invalidKey(forRow: key, codingPath: encoder.codingPath)
                self.focus = .row(r)
            default:
                throw CSVEncoder.Error.invalidContainerRequest(codingPath: encoder.codingPath)
            }
            self.encoder = encoder
        }
        
        var codingPath: [CodingKey] {
            self.encoder.codingPath
        }
    }
}

extension ShadowEncoder.KeyedContainer {
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey:CodingKey {
        var codingPath = self.encoder.codingPath
        switch self.focus {
        case .file:
            guard let rowIndex = key.intValue else { fallthrough }
            codingPath.append(CodecKey(rowIndex))
            let encoder = ShadowEncoder(sink: self.encoder.sink, codingPath: codingPath)
            return KeyedEncodingContainer(ShadowEncoder.KeyedContainer<NestedKey>(unsafeEncoder: encoder, rowIndex: rowIndex))
        case .row:
            let error = CSVEncoder.Error.invalidContainerRequest(codingPath: codingPath)
            return .init(ShadowEncoder.FailContainer<NestedKey>(error: error, encoder: self.encoder))
        }
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        var codingPath = self.encoder.codingPath
        switch self.focus {
        case .file:
            guard let rowIndex = key.intValue else { fallthrough }
            codingPath.append(CodecKey(rowIndex))
            let encoder = ShadowEncoder(sink: self.encoder.sink, codingPath: codingPath)
            return ShadowEncoder.UnkeyedContainer(unsafeEncoder: encoder, rowIndex: rowIndex)
        case .row:
            let error = CSVEncoder.Error.invalidContainerRequest(codingPath: codingPath)
            return ShadowEncoder.FailContainer<CodecKey>(error: error, encoder: self.encoder)
        }
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        var codingPath = self.encoder.codingPath
        switch self.focus {
        case .file: codingPath.append(CodecKey(key.intValue ?? -1))
        case .row:  codingPath.append(CodecKey(-1))
        }
        return ShadowEncoder(sink: self.encoder.sink, codingPath: codingPath)
    }
    
    mutating func superEncoder() -> Encoder {
        var codingPath: [CodingKey] = self.codingPath
        switch self.focus {
        case .file: codingPath.append(CodecKey(0))
        case .row:  codingPath.append(CodecKey(-1))
        }
        return ShadowEncoder(sink: self.encoder.sink, codingPath: codingPath)
    }
}

extension ShadowEncoder.KeyedContainer {
    mutating func encode(_ value: String, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encodeNil(forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        fatalError()
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T:Encodable {
        fatalError()
    }
    
    mutating func encodeConditional<T>(_ object: T, forKey key: Key) throws where T:AnyObject, T:Encodable {
        fatalError()
    }
}

//extension ShadowEncoder.KeyedContainer {
//    mutating func encodeIfPresent(_ value: String?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
//        fatalError()
//    }
//
//    mutating func encodeIfPresent<T>(_ value: T?, forKey key: Key) throws where T:Encodable {
//        fatalError()
//    }
//}

// MARK: -

extension ShadowEncoder.KeyedContainer {
    /// CSV keyed container focus (i.e. where the container is able to operate on).
    private enum Focus {
        /// The container represents the whole CSV file and each encoding operation writes a row/record.
        case file
        /// The container represents a CSV row and each encoding operation outputs a field.
        case row(Int)
    }
}

fileprivate extension CSVEncoder.Error {
    /// Error raised when a coding key representing a row within the CSV file cannot be transformed into an integer value.
    /// - parameter codingPath: The whole coding path, including the invalid row key.
    static func invalidKey(forRow key: CodingKey, codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidPath,
              reason: "The coding key identifying a CSV row couldn't be transformed into an integer value.",
              help: "The provided coding key identifying a CSV row must implement `intValue`.",
              userInfo: ["Coding path": codingPath])
    }
    /// Error raised when a keyed value container is requested on an invalid coding path.
    /// - parameter codingPath: The full chain of containers which generated this error.
    static func invalidContainerRequest(codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidPath,
              reason: "CSV doesn't support more than two nested encoding container.",
              help: "Don't ask for a keyed encoding container on this coding path.",
              userInfo: ["Coding path": codingPath])
    }
    /// Error raised when a value is encoded, but a container was expected by the encoder.
    static func invalidNestedRequired(codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidPath,
              reason: "A nested container is needed to encode at this coding path.",
              help: "Request a nested container instead of trying to decode a value directly.",
              userInfo: ["Coding path": codingPath])
    }
}
