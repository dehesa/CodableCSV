open class CSVDecoderSequence: IteratorProtocol, Sequence {
    private let source: ShadowDecoder.Source
    private var currentIndex: Int = 0

    init(source: ShadowDecoder.Source) {
        self.source = source
    }

    /// Advances to the next row and returns a `CSVRowDecoder`, or `nil` if no next row exists.
    public func next() -> CSVRowDecoder? {
        guard !self.source.isRowAtEnd(index: self.currentIndex) else {
            return nil
        }

        defer { self.currentIndex += 1 }
        let decoder = ShadowDecoder(source: source, codingPath: [IndexKey(self.currentIndex)])
        return CSVRowDecoder(decoder: decoder)
    }
}

public struct CSVRowDecoder {
    /// The representation of the decoding process point-in-time.
    let decoder: ShadowDecoder

    /// Returns a value of the type you specify, decoded from CSV row.
    /// - parameter type: The type of the value to decode from the supplied file.
    /// - throws: `DecodingError`, or `CSVError<CSVReader>`, or the error raised by your custom types.
    public func decode<T:Decodable>(_ type: T.Type) throws -> T {
        return try T(from: decoder)
    }
}
