extension Unicode.Scalar {
    /// Closure transforming some bytes into a unicode scalar.
    /// - returns: The decoded Unicode scalar or `nil` if we are at the end of the stream.
    internal typealias Decoder<I> = (inout I) throws -> Unicode.Scalar? where I:IteratorProtocol, I.Element==UInt8
}

extension String.Encoding {
    /// Returns a decoder to transform a bunch of bytes into a Unicode scalar.
    /// - parameter iterator: The type of byte iterator (commonly parsing a file or data blob.
    /// - returns: If the receiving string encoding is supported, a full-fledge decoder function is returned. Otherwise, `nil` is returned.
    internal func scalarDecoder<I>(iterator: I.Type) -> Unicode.Scalar.Decoder<I>? where I:IteratorProtocol, I.Element==UInt8 {
        switch self.rawValue {
        case Self.ascii.rawValue:
            var decoder = Unicode.UTF8()
            return { (iterator) in
                switch decoder.decode(&iterator) {
                case .scalarValue(let scalar):
                    guard scalar.isASCII else { throw CSVReader.Error(.invalidInput, reason: "The decoded Unicode scalar is not ASCII.", help: "Make sure the CSV only contains ASCII characters or mark the encoding as UTF8.", userInfo: ["Scalar": scalar]) }
                    return scalar
                case .emptyInput: return nil
                case .error: throw CSVReader.Error(.invalidInput, reason: "An error occurred transforming bytes into Unicode scalars.", help: "Check the input data/file for invalid state and try again.")
                }
            }
        case Self.utf8.rawValue:
            var decoder = Unicode.UTF8()
            return { (iterator) in
                switch decoder.decode(&iterator) {
                case .scalarValue(let scalar): return scalar
                case .emptyInput: return nil
                case .error: throw CSVReader.Error(.invalidInput, reason: "An error occurred transforming bytes into Unicode scalars.", help: "Check the input data/file for invalid state and try again.")
                }
            }
//        // UTF16 & Unicode imply: follow the BOM and if it is not there, assume big endian.
//        case Self.utf16.rawValue, Self.unicode.rawValue: fallthrough
        case Self.utf16BigEndian.rawValue:
            return { (iterator) in
                guard let msb = iterator.next() else { return nil }
                guard let lsb = iterator.next() else { throw CSVReader.Error(.invalidInput, reason: "Only 1 byte was decoded in an expected UTF16 width of 2 bytes", help: "Check the last UTF16 character of your input data/file.") }
                return [msb, lsb].withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: 1) {
                        UTF16.decode(UTF16.EncodedScalar(containing: UTF16.CodeUnit(bigEndian: $0.pointee)))
                    }
                }
            }
        case Self.utf16LittleEndian.rawValue:
            return { (iterator) in
                guard let lsb = iterator.next() else { return nil }
                guard let msb = iterator.next() else { throw CSVReader.Error(.invalidInput, reason: "Only 1 byte was decoded in an expected UTF16 width of 2 bytes", help: "Check the last UTF16 character of your input data/file.") }
                return [lsb, msb].withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: 1) {
                        UTF16.decode(UTF16.EncodedScalar(containing: UTF16.CodeUnit(littleEndian: $0.pointee)))
                    }
                }
            }
//        // UTF32 implies: follow the BOM and if it is not there, assume big endian.
//        case Self.utf32.rawValue: fallthrough
        case Self.utf32BigEndian.rawValue:
            return { (iterator) in
                guard let msb = iterator.next() else { return nil }
                guard let ib1 = iterator.next(),
                      let ib2 = iterator.next(),
                      let lsb = iterator.next() else { throw CSVReader.Error(.invalidInput, reason: "An error occurred transforming bytes into Unicode scalars.", help: "Check the last UTF32 character of your input data/file.") }
                return [msb, ib1, ib2, lsb].withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) {
                        UTF32.decode(UTF32.EncodedScalar(UTF32.CodeUnit(bigEndian: $0.pointee)))
                    }
                }
            }
        case Self.utf32LittleEndian.rawValue:
            return { (iterator) in
                guard let lsb = iterator.next() else { return nil }
                guard let ib2 = iterator.next(),
                      let ib1 = iterator.next(),
                      let msb = iterator.next() else { throw CSVReader.Error(.invalidInput, reason: "An error occurred transforming bytes into Unicode scalars.", help: "Check the last UTF32 character of your input data/file.") }
                return [lsb, ib2, ib1, msb].withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) {
                        UTF32.decode(UTF32.EncodedScalar(UTF32.CodeUnit(littleEndian: $0.pointee)))
                    }
                }
            }
        default: return nil
        }
    }
}
