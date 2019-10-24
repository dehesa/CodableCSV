import Foundation

/// A CSV decoding container.
///
/// All CSV decoding container must implement this protocol.
internal protocol DecodingContainer: CodingContainer {
    /// The decoder containing the receiving container as its last decoding chain link.
    var decoder: ShadowDecoder! { get }
    
    /// Designated (and only) way to create a decoding container.
    ///
    /// This initializer will duplicate the given coder and add itself to the result.
    /// - parameter decoder: The decoder that will become `superDecoder` after the end of this call.
    /// - warning: Only a `ShadowDecoder` instance may call this initializer.
    init(decoder: ShadowDecoder) throws
}

extension DecodingContainer {
    var coder: Coder {
        return self.decoder
    }
    
    func superDecoder() throws -> Decoder {
        return self.decoder.superDecoder()
    }
}

/// A decoding container holding an overview of the whole CSV file.
///
/// This container is usually in charge of giving the user rows (one at a time) through unkeyed or keyed decoding containers.
internal protocol FileDecodingContainer: FileContainer, DecodingContainer, RollBackable {
    /// The index of the record to fetch next.
    var currentIndex: Int { get }
}

/// A decoding container holding a CSV record/row.
///
/// This container is usually in charge of giving the user fields (one at a time) through unkeyed or keyed decoding containers.
internal protocol RecordDecodingContainer: RecordContainer, DecodingContainer, RollBackable {
    /// All the fields of the stored record.
    var record: [String] { get }
    /// The index of the field to fetch next.
    var currentIndex: Int { get set }
}

/// The compliant instance can roll back its state to before the operation application.
internal protocol RollBackable {
    /// Rollbacks the changes if the operation returns `nil`.
    mutating func rollBackOnNil<T>(operation: ()->T?) -> T?
}

extension RecordDecodingContainer {
    func rollBackOnNil<T>(operation: () -> T?) -> T? {
        let fieldIndex = self.currentIndex
        guard let result = operation() else {
            self.currentIndex = fieldIndex
            return nil
        }
        return result
    }
}

extension FileDecodingContainer {
    func rollBackOnNil<T>(operation: () -> T?) -> T? {
        let startIndex = self.currentIndex
        guard let result = operation() else {
            guard startIndex == self.currentIndex else {
//                #warning("TODO: Implement rollbacks on File level decoding containers.")
                return nil
            }
            return nil
        }
        return result
    }
}
