extension CSVDecoder {
    public struct LazySequence: IteratorProtocol, Sequence {
        private let source: ShadowDecoder.Source
        private var currentIndex: Int = 0

        init(source: ShadowDecoder.Source) {
            self.source = source
        }

        /// Advances to the next row and returns a `LazySequence.Row`, or `nil` if no next row exists.
        public mutating func next() -> Row? {
            guard !self.source.isRowAtEnd(index: self.currentIndex) else {
                return nil
            }

            defer { self.currentIndex += 1 }
            let decoder = ShadowDecoder(source: source, codingPath: [IndexKey(self.currentIndex)])
            return Row(decoder: decoder)
        }

        public struct Row {
            /// The representation of the decoding process point-in-time.
            private let decoder: ShadowDecoder

            fileprivate init(decoder: ShadowDecoder) {
                self.decoder = decoder
            }

            /// Returns a value of the type you specify, decoded from CSV row.
            /// - parameter type: The type of the value to decode from the supplied file.
            /// - throws: `DecodingError`, or `CSVError<CSVReader>`, or the error raised by your custom types.
            public func decode<T:Decodable>(_ type: T.Type) throws -> T {
                return try T(from: decoder)
            }
        }
    }
}
