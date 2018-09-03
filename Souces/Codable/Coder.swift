import Foundation

/// The instance performing the encoding/decoding work.
internal protocol Coder {
    /// The decoding containers participating in the decoding process.
    var chain: CodingChain { get }
    /// The path of coding keys taken to get to this point in decoding.
    var codingPath: [CodingKey] { get }
    /// Any contextual information set by the user for decoding.
    var userInfo: [CodingUserInfoKey:Any] { get }
}

extension Coder {
    var codingPath: [CodingKey] {
        return self.chain.codingPath
    }
}
