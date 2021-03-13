extension CSVDecoder {
    /// Lazy decoder allowing declarative row-by-row decoding.
    ///
    /// The CSV rows are read _on-demand_ and only decoded when explicitly told so (unlike the default _decode_ functions).
    public final class Lazy: IteratorProtocol, Sequence {
        /// The source of the CSV data.
        private let _source: ShadowDecoder.Source
        /// The row to be read (not decoded) next.
        private var _currentIndex: Int
        /// A dictionary you use to customize the decoding process by providing contextual information.
        public var userInfo: [CodingUserInfoKey:Any] { self._source.userInfo }
        
        /// Designated initalizer passing all the required components.
        /// - parameter source: The data source for the decoder.
        internal init(source: ShadowDecoder.Source) {
            self._source = source
            self._currentIndex = 0
        }
        
        /// Returns a value of the type you specify, decoded from a CSV row.
        /// - attention: This function will throw an error if the file has reached the end. If you are unsure where the CSV file ends, use the `next()` function instead.
        /// - parameter type: The type of the value to decode from the supplied file.
        /// - returns: A CSV row decoded as a type `T`.
        public func decodeRow<T:Decodable>(_ type: T.Type) throws -> T {
            guard let rowDecoder = self.next() else { throw CSVDecoder.Error._unexpectedEnd() }
            return try rowDecoder.decode(type)
        }
        
        /// Returns a value of the type you specify, decoded from a CSV row (if there are still rows to be decoded in the file).
        /// - parameter type: The type of the value to decode from the supplied file.
        /// - returns: A CSV row decoded as a type `T` or `nil` if the CSV file doesn't contain any more rows.
        public func decodeRowIfPresent<T:Decodable>(_ type: T.Type) throws -> T? {
            guard let rowDecoder = self.next() else { return nil }
            return try rowDecoder.decode(type)
        }
        
        /// Ignores the subsequent row.
        public func ignoreRow() throws {
            guard try !self._source.isRowAtEnd(index: self._currentIndex) else { return }
            self._currentIndex += 1
        }
    }
}

extension CSVDecoder.Lazy {
    /// Advances to the next row and returns a `LazyDecoder.Row`, or `nil` if no next row exists.
    public func next() -> CSVDecoder.Lazy.Row? {
        let isAtEnd = (try? self._source.isRowAtEnd(index: self._currentIndex)) ?? false
        guard !isAtEnd else { return nil }
        
        defer { self._currentIndex += 1 }
        let decoder = ShadowDecoder(source: .passUnretained(self._source), codingPath: [IndexKey(self._currentIndex)])
        return Row(decoder: decoder)
    }
    
    /// Pointer to a row within a CSV file that is able to decode it to a custom type.
    public struct Row {
        /// The representation of the decoding process point-in-time.
        private let _decoder: ShadowDecoder
        
        /// Designated initializer passing all the required components.
        /// - parameter decoder: The `Decoder` instance in charge of decoding the CSV data.
        fileprivate init(decoder: ShadowDecoder) {
            self._decoder = decoder
        }
        
        /// Returns a value of the type you specify, decoded from a CSV row.
        /// - parameter type: The type of the value to decode from the supplied file.
        @inline(__always) public func decode<T:Decodable>(_ type: T.Type) throws -> T {
            return try T(from: self._decoder)
        }
    }
}

// MARK: -

fileprivate extension CSVDecoder.Error {
    /// Error raised when the end of the file has been reached unexpectedly.
    static func _unexpectedEnd() -> CSVError<CSVDecoder> {
        .init(.invalidPath,
              reason: "There are no more rows to decode. The file is at the end.",
              help: "Use next() or decodeIfPresent(_:) instead of decode(_:) if you are unsure where the file ends.")
    }
}
