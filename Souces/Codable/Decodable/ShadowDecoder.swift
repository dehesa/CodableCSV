import Foundation

/// The class actually performing all the CSV decoding work.
internal struct ShadowDecoder {
    /// The type of the coding chain used in this decoder.
    typealias DecodingChain = CodingChain<State>
    
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
        let source = try Source(data: data, encoding: encoding, configuration: configuration)
        let chain = try DecodingChain(containers: [])
        self.init(source: source, chain: chain, userInfo: userInfo)
    }
    
    /// Creates a new decoder with the given properties.
    /// - parameter source: The source of the CSV data.
    /// - parameter chain: The decoding containers participating in the decoding process.
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
            return try DecodingFileOrdered(decoder: self)
        case .file(_):
            return try DecodingRecordOrdered(decoder: self)
        case .record(_), .field(_):
            throw DecodingError.invalidNestedContainer(Any.self, codingPath: self.codingPath)
        }
    }
    
    /// - throws: `DecodingError` exclusively (with optional `CSVReader.Error` as *underlying error*).
    func container<Key:CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        switch self.chain.state {
        case .overview:
            return KeyedDecodingContainer(try DecodingFileRandom(decoder: self))
        case .file(_):
            return KeyedDecodingContainer(try DecodingRecordRandom(decoder: self))
        case .record(_), .field(_):
            throw DecodingError.invalidNestedContainer(Any.self, codingPath: self.codingPath)
        }
    }
    
    /// - throws: `DecodingError` exclusively (with optional `CSVReader.Error` as *underlying error*).
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        switch self.chain.state {
        case .overview:
            return try DecodingFileWrapper(decoder: self)
        case .file(_):
            return try DecodingRecordWrapper(decoder: self)
        case .record(_), .field(_):
            return try DecodingField(decoder: self)
        }
    }
}
