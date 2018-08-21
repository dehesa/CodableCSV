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
    /// - throws: `DecodingError` exclusively (with `CSVReader.Error` as *underlying error*).
    init(data: Data, encoding: String.Encoding, configuration: CSV.Configuration, userInfo: [CodingUserInfoKey:Any]) throws {
        self.userInfo = userInfo
        self.source = try Source(data: data, encoding: encoding, configuration: configuration)
        self.chain = DecodingChain(containers: [])
    }
    
    /// Creates a new decoder with the given properties.
    /// - parameter userInfo: Contextual information set by the user for decoding.
    private init(source: Source, chain: DecodingChain, userInfo: [CodingUserInfoKey:Any]) {
        self.userInfo = userInfo
        self.source = source
        self.chain = chain
    }
    
    /// Returns a duplicate from the receiving decoder except its chain has added the given list of decoding containers.
    func subDecoder(adding container: DecodingContainer) -> ShadowDecoder {
        let chain = self.chain.adding(containers: container)
        return ShadowDecoder(source: self.source, chain: chain, userInfo: self.userInfo)
    }
    
    /// Returns a duplicate from the receiving decoder except its chain has removed the last decoding container
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
            return OrderedFile(superDecoder: self)
        case .file(_):
            return try OrderedRow(superDecoder: self)
        case .record(_), .field(_):
            throw DecodingError.invalidNestedContainer(Any.self, codingPath: self.codingPath)
        }
    }
    
    /// - throws: `DecodingError` exclusively (with optional `CSVReader.Error` as *underlying error*).
    func container<Key:CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
//        if case .none = self.fileContainer {
//            let result = UnorderedFile<Key>(decoder: self, reader: self.reader, codingPath: self.codingPath)
//            self.containerChain.append(result)
//            return KeyedDecodingContainer(result)
//        } else if case .none = self.rowContainer {
//            let result = UnorderedRow<Key>(decoder: self, codingPath: self.codingPath)
//            self.containerChain.append(result)
//            return KeyedDecodingContainer(result)
//        } else {
//            throw DecodingError.invalidNestedContainer(Field.self, codingPath: self.codingPath)
//        }
        #warning("TODO:")
        fatalError()
    }
    
    /// - throws: `DecodingError` exclusively (with optional `CSVReader.Error` as *underlying error*).
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        #warning("TODO:")
        fatalError()
    }
}
