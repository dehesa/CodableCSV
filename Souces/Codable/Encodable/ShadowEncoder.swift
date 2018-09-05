import Foundation

/// The class actually performing all the CSV encoding work.
internal struct ShadowEncoder: Coder {
    let chain: CodingChain
    let userInfo: [CodingUserInfoKey:Any]
    /// The output of the encoding process.
    let output: Output
    
    /// Creates a new encoder with the given properties.
    /// - parameter output: The output of the encoding process.
    /// - parameter source: The instance writing everything to the output.
    /// - parameter chain: The encoding containers participating in the encoding process.
    /// - parameter userInfo: Contextual information set by the user for encoding.
    private init(output: Output, chain: CodingChain, userInfo: [CodingUserInfoKey:Any]) {
        self.userInfo = userInfo
        self.output = output
        self.chain = chain
    }
    
    /// Initializer used as entry point from the outside.
    /// - parameter output: The type of output requested (e.g. data, file, etc.).
    /// - parameter configuration: General CSV configuration to use in the encoding process.
    /// - parameter userInfo: Contextual information set by the user for encoding.
    /// - throws: `EncodingError` exclusively.
    init(output: Output.Request, configuration: EncoderConfiguration, userInfo: [CodingUserInfoKey:Any]) throws {
        let output = try Output.make(output, configuration: configuration)
        self.init(output: output, chain: CodingChain(), userInfo: userInfo)
    }
    
    /// Returns a duplicate from the receiving decoder and adds the given list of containers to its coding chain.
    func subEncoder(adding container: EncodingContainer) throws -> ShadowEncoder {
        guard let chain = self.chain.adding(containers: container) else {
            let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The requested decoding container cannot be place in the current codingPath.")
            throw EncodingError.invalidValue(container, context)
        }
        return ShadowEncoder(output: self.output, chain: chain, userInfo: self.userInfo)
    }
    
    /// Returns a duplicate from the receiving decoder except it removes the last container from its coding chain.
    func superEncoder() -> ShadowEncoder {
        let chain = self.chain.reducing(by: 1)
        return ShadowEncoder(output: self.output, chain: chain, userInfo: self.userInfo)
    }
}

extension ShadowEncoder: Encoder {
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        switch self.chain.state {
        case .overview:
            return try! EncodingFileOrdered(encoder: self)
        case .file(_):
            return try! EncodingRecordOrdered(encoder: self)
        case .record(_), .field(_):
            #warning("TODO: Look at the Coding Chain state too.")
            fatalError()
        }
    }
    
    func container<Key:CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        switch self.chain.state {
        case .overview:
            let fileContainer = try! EncodingFileRandom<Key>(encoder: self)
            return KeyedEncodingContainer(fileContainer)
        case .file(_):
            let fileContainer = try! EncodingRecordRandom<Key>(encoder: self)
            return KeyedEncodingContainer(fileContainer)
        case .record(_), .field(_):
            #warning("TODO: Look at the Coding Chain state too.")
            fatalError()
        }
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        switch self.chain.state {
        case .overview:
            return try! EncodingFileWrapper(encoder: self)
        case .file(_):
            return try! EncodingRecordWrapper(encoder: self)
        case .record(_), .field(_):
            return try! EncodingField(encoder: self)
        }
    }
}
