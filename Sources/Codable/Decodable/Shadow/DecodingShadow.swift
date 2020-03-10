import Foundation

/// The instance actually performing all the CSV decoding work.
///
/// A shadow decoder represents a moment in time on the decoding process. Therefore it is a inmutable structure.
internal struct ShadowDecoder: Decoder {
    /// The source of the CSV data.
    let source: Source
    /// The path of coding keys taken to get to this point in decoding.
    private(set) var codingPath: [CodingKey]
    /// Any contextual information set by the user for decoding.
    var userInfo: [CodingUserInfoKey:Any] { self.source.userInfo }
    
    /// Initializer used at the very beginning of the decoding process.
    /// - parameter data: The data blob already preloaded in memory.
    /// - parameter encoding: The String encoding to decode the data blob as text.
    /// - parameter configuration: General CSV configuration to use in the data blob.
    /// - parameter userInfo: Contextual information set by the user for decoding.
    init(data: Data, encoding: String.Encoding, configuration: CSVDecoder.Configuration, userInfo: [CodingUserInfoKey:Any]) throws {
        self.source = try Source(data: data, encoding: encoding, configuration: configuration, userInfo: userInfo)
        self.codingPath = []
    }
    /// Duplicates the receiving shadow decoder and appends to that duplicate the provided coding key.
    func duplicate(appendingKey codingKey: CodingKey) -> ShadowDecoder {
        var result = self
        result.codingPath.append(codingKey)
        return result
    }
    /// Duplicates the receiving shadow decoder and appends to that duplicate the provided coding keys.
    func duplicate(appendingKeys codingKeys: CodingKey...) -> ShadowDecoder {
        var result = self
        result.codingPath.append(contentsOf: codingKeys)
        return result
    }
}

extension ShadowDecoder {
    /// Returns the data stored in this decoder as represented in a container keyed by the given key type.
    /// - parameter type: The key type to use for the container.
    /// - returns: A keyed decoding container view into this decoder.
    func container<Key:CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        try KeyedDecodingContainer<Key>(KeyedContainer(decoder: self))
    }
    
    /// Returns the data stored in this decoder as represented in a container appropriate for holding values with no keys.
    /// - returns: An unkeyed container view into this decoder.
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try UnkeyedContainer(decoder: self)
    }
    
    /// Returns the data stored in this decoder as represented in a container appropriate for holding a single primitive value.
    /// - returns: A single value container view into this decoder.
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        try SingleValueContainer(decoder: self)
    }
}
