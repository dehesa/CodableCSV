import Foundation

/// A CSV decoding container.
///
/// All CSV decoding container must implement this protocol.
internal protocol DecodingContainer {
    /// The coding key representing the receiving container.
    var codingKey: CodingKey { get }
    /// The decoder containing the receiving container as its last decoding chain link.
    var decoder: ShadowDecoder! { get }
}

extension DecodingContainer {
    /// The path of coding keys taken to get to this point in decoding.
    ///
    /// This path doesn't include the receiving container.
    var codingPath: [CodingKey] {
        var result = self.decoder.codingPath
        if !result.isEmpty {
            result.removeLast()
        }
        return result
    }
    
    func superDecoder() throws -> Decoder {
        return self.decoder.superDecoder()
    }
}

///
internal protocol FileDecodingContainer: DecodingContainer {
    /// The newly created file decoding container will duplicate the receiving decoder and attach itself to it.
    /// - parameter decoder: The `superDecoder` calling the `unkeyedDecodingContainer()` function.
    init(superDecoder decoder: ShadowDecoder)
}

///
internal protocol RecordDecodingContainer: DecodingContainer {
    /// The newly created record decoding container will duplicate the receiving decoder and attach itself to it.
    /// - parameter decoder: The `superDecoder` calling the `unkeyedDecodingContainer()` function.
    init(superDecoder decoder: ShadowDecoder) throws
}

///
internal protocol FieldDecodingContainer: DecodingContainer {
    
}
