extension CSVDecoder {
    /// Swift sequence type giving access to all the "undecoded" CSV rows.
    ///
    /// The CSV rows are read _on-demand_ and only decoded when explicitly told so (unlike the default _decode_ functions).
    public struct LazySequence: IteratorProtocol, Sequence {
        /// The source of the CSV data.
        private let _source: ShadowDecoder.Source
        /// The row to be read (not decoded) next.
        private var _currentIndex: Int = 0
        /// Designated initalizer passing all the required components.
        /// - parameter source: The data source for the decoder.
        internal init(source: ShadowDecoder.Source) {
            self._source = source
        }

        /// Advances to the next row and returns a `LazySequence.Row`, or `nil` if no next row exists.
        public mutating func next() -> RowDecoder? {
            guard !self._source.isRowAtEnd(index: self._currentIndex) else { return nil }

            defer { self._currentIndex += 1 }
            let decoder = ShadowDecoder(source: self._source, codingPath: [IndexKey(self._currentIndex)])
            return RowDecoder(decoder: decoder)
        }
    }
}

extension CSVDecoder.LazySequence {
    /// Pointer to a row within a CSV file that is able to decode it to a custom type.
    public struct RowDecoder {
        /// The representation of the decoding process point-in-time.
        private let _decoder: ShadowDecoder
        
        /// Designated initializer passing all the required components.
        /// - parameter decoder: The `Decoder` instance in charge of decoding the CSV data.
        fileprivate init(decoder: ShadowDecoder) {
            self._decoder = decoder
        }
        
        /// Returns a value of the type you specify, decoded from CSV row.
        /// - parameter type: The type of the value to decode from the supplied file.
        /// - throws: `DecodingError`, or `CSVError<CSVReader>`, or the error raised by your custom types.
        @inline(__always) public func decode<T:Decodable>(_ type: T.Type) throws -> T {
            return try T(from: self._decoder)
        }
    }
}
