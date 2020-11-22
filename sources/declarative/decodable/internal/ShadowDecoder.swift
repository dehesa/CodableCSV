/// The instance actually performing all the CSV decoding work.
///
/// A shadow decoder represents a moment in time on the decoding process. Therefore it is a immutable structure.
internal struct ShadowDecoder: Decoder {
    /// The source of the CSV data.
    let source: Unmanaged<Source>
    /// The path of coding keys taken to get to this point in decoding.
    let codingPath: [CodingKey]
    
    /// Designated initializer passing all required components.
    /// - parameter source: The data source for the decoder.
    /// - parameter codingPath: The path taken to create the decoder instance.
    init(source: Unmanaged<Source>, codingPath: [CodingKey]) {
        self.source = source
        self.codingPath = codingPath
    }
    
    /// Any contextual information set by the user for decoding.
    var userInfo: [CodingUserInfoKey:Any] {
        self.source._withUnsafeGuaranteedRef {
            $0.userInfo
        }
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
