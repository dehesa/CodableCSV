import Foundation

/// A CSV decoding container.
///
/// All CSV decoding container must implement this protocol.
internal protocol DecodingContainer {
    /// The coding key representing the receiving container.
    var codingKey: CSV.Key { get }
    /// The decoder containing the receiving container as its last decoding chain link.
    var decoder: ShadowDecoder! { get }
    
    /// Designated (and only) way to create a decoding container.
    ///
    /// This initializer will duplicate the given decoder
    /// - parameter decoder: The `superDecoder` calling the `unkeyedDecodingContainer()` function.
    /// - warning: Only a `ShadowContainer` instance may call this initializer.
    init(decoder: ShadowDecoder) throws
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

/// A decoding container holding an overview of the whole CSV file.
///
/// This container is usually in charge of giving the user rows (one at a time) through unkeyed or keyed decoding containers.
internal protocol FileDecodingContainer: class, DecodingContainer, RollBackable {
    /// The index of the record to fetch next.
    var currentIndex: Int { get }
}

/// A decoding container holding a CSV record/row.
///
/// This container is usually in charge of giving the user fields (one at a time) through unkeyed or keyed decoding containers.
internal protocol RecordDecodingContainer: class, DecodingContainer, RollBackable {
    /// All the fields of the stored record.
    var record: [String] { get }
    /// The row index within the CSV file.
    var recordIndex: Int { get }
    /// The index of the field to fetch next.
    var currentIndex: Int { get set }
}

/// A single value container that is wrapping a file or record decoding container.
internal protocol WrapperDecodingContainer: ValueContainer {}
