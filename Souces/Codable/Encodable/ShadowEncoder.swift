import Foundation

/// The class actually performing all the CSV encoding work.
internal struct ShadowEncoder {
    /// The type of the coding chain used in this decoder.
    typealias EncodingChain = CodingChain<State>
    
    let userInfo: [CodingUserInfoKey:Any]
    /// The output of the encoding process.
    let output: Output
    /// The instance writing everything to the output.
    let sink: Sink
    /// The encoding containers participating in the encoding process.
    let chain: EncodingChain
    
    /// Initializer used as entry point from the outside.
    /// - parameter output: The type of output requested (e.g. data, file, etc.).
    /// - parameter configuration: General CSV configuration to use in the encoding process.
    /// - parameter userInfo: Contextual information set by the user for encoding.
    /// - throws: `EncodingError` exclusively.
    init(output: Output.Request, configuration: CSV.Configuration, userInfo: [CodingUserInfoKey:Any]) throws {
        let output = try Output.make(output)
        let sink = try Sink(stream: output.stream, encoding: output.encoding, configuration: configuration)
        let chain = try EncodingChain(containers: [])
        self.init(output: output, sink: sink, chain: chain, userInfo: userInfo)
    }
    
    /// Creates a new encoder with the given properties.
    /// - parameter output: The output of the encoding process.
    /// - parameter sink: The instance writing everything to the output.
    /// - parameter chain: The encoding containers participating in the encoding process.
    /// - parameter userInfo: Contextual information set by the user for encoding.
    private init(output: Output, sink: Sink, chain: EncodingChain, userInfo: [CodingUserInfoKey:Any]) {
        self.userInfo = userInfo
        self.output = output
        self.sink = sink
        self.chain = chain
    }
}

extension ShadowEncoder: Encoder {
    var codingPath: [CodingKey] {
        return self.chain.codingPath
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        #warning("TODO")
        fatalError()
    }
    
    func container<Key:CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        #warning("TODO")
        fatalError()
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        #warning("TODO")
        fatalError()
    }
}
