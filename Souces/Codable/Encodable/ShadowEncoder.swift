import Foundation

/// The class actually performing all the CSV encoding work.
internal struct ShadowEncoder {
    let userInfo: [CodingUserInfoKey:Any]
    /// The output of the encoding process.
    let output: Output
    
    /// Initializer used as entry point from the outside.
    /// - parameter output: The type of output requested (e.g. data, file, etc.).
    /// - parameter configuration: General CSV configuration to use in the encoding process.
    /// - parameter userInfo: Contextual information set by the user for encoding.
    /// - throws: `EncodingError` exclusively.
    init(output: Output.Request, configuration: CSV.Configuration, userInfo: [CodingUserInfoKey:Any]) throws {
        self.userInfo = userInfo
        self.output = try Output.make(output)
    }
}

extension ShadowEncoder: Encoder {
    var codingPath: [CodingKey] {
        #warning("TODO")
        fatalError()
    }

    func container<Key:CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        #warning("TODO")
        fatalError()
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        #warning("TODO")
        fatalError()
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        #warning("TODO")
        fatalError()
    }
}
