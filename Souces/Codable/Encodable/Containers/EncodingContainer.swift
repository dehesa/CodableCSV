import Foundation

/// A CSV encoding container.
///
/// All CSV encoding containers must implement this protocol.
internal protocol EncodingContainer: CodingContainer {
    /// The encoder containing the receiving container as its last encoding chain link.
    var encoder: ShadowEncoder! { get }
    
    /// Designated (and only) way to create an encoding container.
    ///
    /// This initializer will duplicate the given coder and add itself to the result.
    /// - parameter encoder: The encoder that will become `superEncoder` after the end of this call.
    /// - warning: Only a `ShadowEncoder` instance may call this initializer.
    /// - throws: `EncodingError` exclusively.
    init(encoder: ShadowEncoder) throws
}

extension EncodingContainer {
    var coder: Coder {
        return self.encoder
    }
    
    func superEncoder() -> Encoder {
        return self.encoder.superEncoder()
    }
}
