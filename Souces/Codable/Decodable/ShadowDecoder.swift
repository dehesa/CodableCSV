import Foundation

/// Class actually performing all the CSV decoding work.
internal struct ShadowDecoder {
    let userInfo: [CodingUserInfoKey:Any]
    /// The source of the CSV data.
    let source: Source
    /// The decoding containers participating in the decoding process.
    let chain: DecodingChain
    
    /// Initializer used at the very beginning of the decoding process.
    /// - parameter data: The data blob already preloaded in memory.
    /// - parameter encoding: The String encoding to decode the data blob as text.
    /// - parameter configuration: General CSV configuration to use in the data blob.
    /// - parameter userInfo: Contextual information set by the user for decoding.
    /// - throws: `DecodingError` exclusively (with `CSVReader.Error` as *underlying errors*).
    init(data: Data, encoding: String.Encoding, configuration: CSV.Configuration, userInfo: [CodingUserInfoKey:Any]) throws {
        self.userInfo = userInfo
        self.source = try Source(data: data, encoding: encoding, configuration: configuration)
        self.chain = try DecodingChain(containers: [])
    }
    
    /// Creates a new decoder with the given properties.
    /// - parameter userInfo: Contextual information set by the user for decoding.
    private init(source: Source, chain: DecodingChain, userInfo: [CodingUserInfoKey:Any]) {
        self.userInfo = userInfo
        self.source = source
        self.chain = chain
    }
    
    /// Returns a duplicate from the receiving decoder and adds the given list of decoding containers to its decoding chain.
    func subDecoder(adding container: DecodingContainer) throws -> ShadowDecoder {
        let chain = try self.chain.adding(containers: container)
        return ShadowDecoder(source: self.source, chain: chain, userInfo: self.userInfo)
    }
    
    /// Returns a duplicate from the receiving decoder except and removes the last decoding container from its decoding chain.
    func superDecoder() -> ShadowDecoder {
        let chain = self.chain.reducing(by: 1)
        return ShadowDecoder(source: self.source, chain: chain, userInfo: self.userInfo)
    }
}

extension ShadowDecoder: Decoder {
    var codingPath: [CodingKey] {
        return self.chain.codingPath
    }
    
    /// - throws: `DecodingError` exclusively (with optional `CSVReader.Error` as *underlying error*).
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        switch self.chain.state {
        case .overview:
            return try OrderedFile(decoder: self)
        case .file(_):
            return try OrderedRecord(decoder: self)
        case .record(_), .field(_):
            throw DecodingError.invalidNestedContainer(Any.self, codingPath: self.codingPath)
        }
    }
    
    /// - throws: `DecodingError` exclusively (with optional `CSVReader.Error` as *underlying error*).
    func container<Key:CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        switch self.chain.state {
        case .overview:
            return KeyedDecodingContainer(try UnorderedFile(decoder: self))
        case .file(_):
            return KeyedDecodingContainer(try UnorderedRecord(decoder: self))
        case .record(_), .field(_):
            throw DecodingError.invalidNestedContainer(Any.self, codingPath: self.codingPath)
        }
    }
    
    /// - throws: `DecodingError` exclusively (with optional `CSVReader.Error` as *underlying error*).
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        switch self.chain.state {
        case .overview:
            return try FileWrapper(decoder: self)
        case .file(_):
            #warning("TODO: If the top is a file, but it is a single value, make a field.")
            return try RecordWrapper(decoder: self)
        case .record(_), .field(_):
            return try Field(decoder: self)
        }
    }
}
