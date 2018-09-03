import Foundation

extension ShadowEncoder {
    /// Container that will hold one CSV record.
    internal final class EncodingRecordOrdered: RecordEncodingContainer, UnkeyedEncodingContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            fatalError()
            
            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        /// The number of elements encoded into the container.
        public var count: Int {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes a null value.
        ///
        /// - throws: `EncodingError.invalidValue` if a null value is invalid in the
        ///   current context for this format.
        public func encodeNil() throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: Bool) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: String) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: Double) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: Float) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: Int) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: Int8) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: Int16) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: Int32) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: Int64) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: UInt) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: UInt8) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: UInt16) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: UInt32) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode(_ value: UInt64) throws {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the given value.
        ///
        /// - parameter value: The value to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encode<T>(_ value: T) throws where T : Encodable {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes a reference to the given object only if it is encoded
        /// unconditionally elsewhere in the payload (previously, or in the future).
        ///
        /// For encoders which don't support this feature, the default implementation
        /// encodes the given object unconditionally.
        ///
        /// For formats which don't support this feature, the default implementation
        /// encodes the given object unconditionally.
        ///
        /// - parameter object: The object to encode.
        /// - throws: `EncodingError.invalidValue` if the given value is invalid in
        ///   the current context for this format.
        public func encodeConditional<T>(_ object: T) throws where T : AnyObject, T : Encodable {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == Bool {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == String {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == Double {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == Float {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == Int {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == Int8 {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == Int16 {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == Int32 {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == Int64 {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == UInt {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == UInt8 {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == UInt16 {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == UInt32 {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element == UInt64 {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes the elements of the given sequence.
        ///
        /// - parameter sequence: The sequences whose contents to encode.
        /// - throws: An error if any of the contained values throws an error.
        public func encode<T>(contentsOf sequence: T) throws where T : Sequence, T.Element : Encodable {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes a nested container keyed by the given type and returns it.
        ///
        /// - parameter keyType: The key type to use for the container.
        /// - returns: A new keyed encoding container.
        public func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes an unkeyed encoding container and returns it.
        ///
        /// - returns: A new unkeyed encoding container.
        public func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            #warning("TODO")
            fatalError()
        }
        
        /// Encodes a nested container and returns an `Encoder` instance for encoding
        /// `super` into that container.
        ///
        /// - returns: A new encoder to pass to `super.encode(to:)`.
        public func superEncoder() -> Encoder {
            #warning("TODO")
            fatalError()
        }
    }
}
