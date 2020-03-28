import Foundation

extension ShadowEncoder {
    /// Unkeyed container for the CSV shadow encoder.
    ///
    /// This contaienr lets you sequentially write CSV rows or specific fields within a single rows.
    struct UnkeyedContainer: UnkeyedEncodingContainer {
        /// The representation of the encoding process point-in-time.
        private let encoder: ShadowEncoder
        /// The focus for this container.
        private let focus: Focus
        /// Depending on the container's focus, this index represents the next row or the next field to decode.
        private(set) var currentIndex: Int
        
        /// Fast initializer that doesn't perform any checks on the coding path (assuming it is valid).
        /// - parameter encoder: The `Encoder` instance in charge of encoding CSV data.
        /// - parameter rowIndex: The CSV row targeted for encoding.
        init(unsafeEncoder encoder: ShadowEncoder, rowIndex: Int) {
            self.encoder = encoder
            self.focus = .row(rowIndex)
            self.currentIndex = 0
        }
        
        /// Creates a unkeyed container only if the passed encoder's coding path is valid.
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
            self.currentIndex = 0
            self.encoder = encoder
        }
        
        var codingPath: [CodingKey] {
            self.encoder.codingPath
        }
        
        var count: Int {
            let sink = self.encoder.sink
            switch self.focus {
            case .file: return sink.numEncodedRows
            case .row(let rowIndex): return sink.numEncodedFields(at: rowIndex)
            }
        }
    }
}

extension ShadowEncoder.UnkeyedContainer {
    mutating func nestedContainer<NestedKey:CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        var codingPath = self.encoder.codingPath
        switch self.focus {
        case .file:
            let rowIndex = self.currentIndex
            codingPath.append(IndexKey(rowIndex))
            let encoder = ShadowEncoder(sink: self.encoder.sink, codingPath: codingPath)
            self.currentIndex += 1
            return .init(ShadowEncoder.KeyedContainer(unsafeEncoder: encoder, rowIndex: rowIndex))
        case .row:
            let error = CSVEncoder.Error.invalidContainerRequest(codingPath: codingPath)
            return .init(ShadowEncoder.InvalidContainer<NestedKey>(error: error, encoder: self.encoder))
        }
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        var codingPath = self.encoder.codingPath
        switch self.focus {
        case .file:
            let rowIndex = self.currentIndex
            codingPath.append(IndexKey(rowIndex))
            let encoder = ShadowEncoder(sink: self.encoder.sink, codingPath: codingPath)
            self.currentIndex += 1
            return Self(unsafeEncoder: encoder, rowIndex: rowIndex)
        case .row:
            let error = CSVEncoder.Error.invalidContainerRequest(codingPath: codingPath)
            return ShadowEncoder.InvalidContainer<IndexKey>(error: error, encoder: self.encoder)
        }
    }
    
    mutating func superEncoder() -> Encoder {
        var codingPath = self.encoder.codingPath
        switch self.focus {
        case .file:
            codingPath.append(IndexKey(self.currentIndex))
            self.currentIndex += 1
        case .row:
            codingPath.append(InvalidKey())
        }
        return ShadowEncoder(sink: self.encoder.sink, codingPath: codingPath)
    }
}

extension ShadowEncoder.UnkeyedContainer {
    mutating func encode(_ value: String) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encodeNil() throws {
        var container = try self.fieldContainer()
        try container.encodeNil()
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: Bool) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: Int) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: Int8) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: Int16) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: Int32) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: Int64) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: UInt) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: UInt8) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: UInt16) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: UInt32) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: UInt64) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: Float) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode(_ value: Double) throws {
        var container = try self.fieldContainer()
        try container.encode(value)
        self.currentIndex += 1
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        switch value {
        case let date as Date:
            var container = try self.fieldContainer()
            try container.encode(date)
        case let data as Data:
            var container = try self.fieldContainer()
            try container.encode(data)
        case let num as Decimal:
            var container = try self.fieldContainer()
            try container.encode(num)
        case let url as URL:
            try self.fieldContainer().encode(url)
        default:
            var codingPath = self.encoder.codingPath
            codingPath.append(IndexKey(self.currentIndex))
            
            let encoder = ShadowEncoder(sink: self.encoder.sink, codingPath: codingPath)
            try value.encode(to: encoder)
        }
        
        self.currentIndex += 1
    }
    
//    mutating func encodeConditional<T>(_ object: T) throws where T:AnyObject, T:Encodable {
//        fatalError()
//    }
}

//extension ShadowEncoder.UnkeyedContainer {
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==String {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Bool {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Int {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Int8 {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Int16 {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Int32 {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Int64 {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==UInt {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==UInt8 {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==UInt16 {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==UInt32 {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==UInt64 {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Float {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element==Double {
//        fatalError()
//    }
//
//    mutating func encode<T>(contentsOf sequence: T) throws where T:Sequence, T.Element:Encodable {
//        fatalError()
//    }
//}

// MARK: -

extension ShadowEncoder.UnkeyedContainer {
    /// CSV unkeyed container focus (i.e. where the container is able to operate on).
    private enum Focus {
        /// The container represents the whole CSV file and each encoding operation writes a row/record.
        case file
        /// The container represents a CSV row and each encoding operation outputs a field.
        case row(Int)
    }
    
    /// Returns a single value container to decode a single field within a row.
    /// - returns: The single value container with the field encoding functionality.
    private mutating func fieldContainer() throws -> ShadowEncoder.SingleValueContainer {
        let index: (row: Int, field: Int)
        var codingPath = self.encoder.codingPath
        codingPath.append(IndexKey(self.currentIndex))
        
        switch self.focus {
        case .row(let rowIndex):
            index = (rowIndex, self.currentIndex)
        case .file:
            // Values are only allowed to be decoded directly from a nested container in "file level" if the CSV rows have a single column.
            guard self.encoder.sink.numExpectedFields == 1 else { throw CSVEncoder.Error.invalidNestedRequired(codingPath: self.codingPath) }
            index = (self.currentIndex, 0)
            codingPath.append(IndexKey(index.field))
        }
        
        let encoder = ShadowEncoder(sink: self.encoder.sink, codingPath: codingPath)
        return .init(unsafeEncoder: encoder, rowIndex: index.row, fieldIndex: index.field)
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
    /// Error raised when a unkeyed value container is requested on an invalid coding path.
    /// - parameter codingPath: The full encoding chain.
    static func invalidContainerRequest(codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidPath,
              reason: "CSV doesn't support more than two nested encoding container.",
              help: "Don't ask for a unkeyed encoding container on this coding path.",
              userInfo: ["Coding path": codingPath])
    }
    /// Error raised when a value is encoded, but a container was expected by the encoder.
    /// - parameter codingPath: The full encoding chain.
    static func invalidNestedRequired(codingPath: [CodingKey]) -> CSVError<CSVEncoder> {
        .init(.invalidPath,
              reason: "A nested container is needed to encode at this coding path.",
              help: "Request a nested container instead of trying to decode a value directly.",
              userInfo: ["Coding path": codingPath])
    }
}
