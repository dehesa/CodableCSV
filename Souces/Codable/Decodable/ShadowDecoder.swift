import Foundation

/// The instance actually performing all the CSV decoding work.
internal struct ShadowDecoder: Coder {
    let chain: CodingChain
    let userInfo: [CodingUserInfoKey:Any]
    /// The source of the CSV data.
    let source: Source
    
    /// Creates a new decoder with the given properties.
    /// - parameter source: The source of the CSV data.
    /// - parameter chain: The decoding containers participating in the decoding process.
    /// - parameter userInfo: Contextual information set by the user for decoding.
    private init(source: Source, chain: CodingChain, userInfo: [CodingUserInfoKey:Any]) {
        self.userInfo = userInfo
        self.source = source
        self.chain = chain
    }
    
    /// Initializer used at the very beginning of the decoding process.
    /// - parameter data: The data blob already preloaded in memory.
    /// - parameter encoding: The String encoding to decode the data blob as text.
    /// - parameter configuration: General CSV configuration to use in the data blob.
    /// - parameter userInfo: Contextual information set by the user for decoding.
    /// - throws: `DecodingError` exclusively (with `CSVReader.Error` as *underlying errors*).
    init(data: Data, encoding: String.Encoding, configuration: DecoderConfiguration, userInfo: [CodingUserInfoKey:Any]) throws {
        let source = try Source(data: data, encoding: encoding, configuration: configuration)
        self.init(source: source, chain: CodingChain(), userInfo: userInfo)
    }
    
    /// Returns a duplicate from the receiving decoder and adds the given list of containers to its coding chain.
    func subDecoder(adding container: DecodingContainer) throws -> ShadowDecoder {
        guard let chain = self.chain.adding(containers: container) else {
            let context: DecodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The requested decoding container cannot be place in the current codingPath.")
            throw DecodingError.typeMismatch(type(of: container), context)
        }
        return ShadowDecoder(source: self.source, chain: chain, userInfo: self.userInfo)
    }
    
    /// Returns a duplicate from the receiving decoder except it removes the last container from its coding chain.
    func superDecoder() -> ShadowDecoder {
        let chain = self.chain.reducing(by: 1)
        return ShadowDecoder(source: self.source, chain: chain, userInfo: self.userInfo)
    }
}

extension ShadowDecoder: Decoder {
    /// - throws: `DecodingError` exclusively (with optional `CSVReader.Error` as *underlying error*).
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        switch self.chain.state {
        case .overview:
            return try! DecodingFileOrdered(decoder: self)
        case .file(_):
            return try! DecodingRecordOrdered(decoder: self)
        case .record(_), .field(_):
            throw DecodingError.invalidNestedContainer(Any.self, codingPath: self.codingPath)
        }
    }
    
    /// - throws: `DecodingError` exclusively (with optional `CSVReader.Error` as *underlying error*).
    func container<Key:CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        switch self.chain.state {
        case .overview:
            let fileContainer = try DecodingFileRandom<Key>(decoder: self)
            return KeyedDecodingContainer(fileContainer)
        case .file(_):
            let fileContainer = try DecodingRecordRandom<Key>(decoder: self)
            return KeyedDecodingContainer(fileContainer)
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
