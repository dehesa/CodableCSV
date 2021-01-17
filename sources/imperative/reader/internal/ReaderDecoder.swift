import Foundation

internal extension CSVReader {
    /// Closure where each time that is executed it generates a new scalar (from the input data), it throws an error, or returns `nil` indicating the end of the file.
    typealias ScalarDecoder = () throws -> Unicode.Scalar?
    
    /// Creates a custom `Unicode.Scalar` iterator wrapping a simple scalar iterator (usually a `String.UnicodeScalarView.Iterator`).
    /// - parameter scalarIterator: Simple iterator returning a new `Unicode.Scalar` for each call of `next()`.
    /// - returns: A closure decoding scalars.
    static func makeDecoder<I>(from scalarIterator: I) -> ScalarDecoder where I:IteratorProtocol, I.Element==Unicode.Scalar {
        var iterator = scalarIterator
        return { iterator.next() }
    }
    
    /// Creates a custom `Unicode.Scalar` iterator wraping a byte-by-byte iterator reading a data blob.
    /// - parameter byteIterator: Byte-by-byte iterator.
    /// - parameter encoding: The `String` encoding used to interpreted the read bytes.
    /// - parameter firstBytes: Bytes to be appended at the beginning of the byte buffer.
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: A closure decoding scalars.
    static func makeDecoder<I>(from byteIterator: I, encoding: String.Encoding, firstBytes: [UInt8]) throws -> ScalarDecoder where I:IteratorProtocol, I.Element==UInt8 {
        let buffer = _IteratorBuffer(iterator: byteIterator, bytes: firstBytes)
        return try Self._makeDecoder(from: buffer, encoding: encoding, onEmpty: { return })
    }
    
    /// Creates a custom `Unicode.Scalar` iterator wrapping an input stream providing byte data.
    /// - parameter stream: Input stream providing the input data.
    /// - parameter encoding: The `String` encoding used to interpreted the read bytes.
    /// - parameter chunk: The number of bytes read each the file is "touched".
    /// - parameter firstBytes: Bytes to be appended at the beginning of the byte buffer.
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - seealso: [Text streaming in the Standard Library](https://forums.swift.org/t/text-streaming-in-standard-library/19328)
    static func makeDecoder(from stream: InputStream, encoding: String.Encoding, chunk: Int, firstBytes: [UInt8]) throws -> ScalarDecoder {
        // For optimization purposes the CSV data is read in chunks and the bytes are stored in an intermediate buffer.
        let buffer = _StreamBuffer(bytes: firstBytes, stream: stream, chunk: chunk)
        let unmanagedBuffer = Unmanaged<_StreamBuffer>.passUnretained(buffer)
        return try Self._makeDecoder(from: buffer, encoding: encoding, onEmpty: {
            guard case .error(let error) = unmanagedBuffer._withUnsafeGuaranteedRef({ $0.status }) else { return }
            throw error
        })
    }
}

fileprivate extension CSVReader {
    /// Creates a custom `Unicode.Scalar` iterator wraping a byte-by-byte iterator.
    /// - parameter byteIterator: Byte-by-byte iterator.
    /// - parameter encoding: The `String` encoding used to interpreted the read bytes.
    /// - parameter onEmpty: Closure used to check whether the "no-more-bytes" received event is actually referring to no bytes or to a low-level error.
    /// - throws: `CSVError<CSVReader>` exclusively.
    static func _makeDecoder<I>(from byteIterator: I, encoding: String.Encoding, onEmpty: @escaping () throws -> Void) throws -> ScalarDecoder where I:IteratorProtocol, I.Element==UInt8 {
        switch encoding {
        case .ascii:
            var iterator = byteIterator
            return {
                guard let byte = iterator.next() else { try onEmpty(); return nil }
                guard Unicode.ASCII.isASCII(byte) else { throw Error._invalidASCII(byte: byte) }
                return Unicode.ASCII.decode(.init(byte))
                
            }
        case .utf8:
            var (codec, iterator) = (Unicode.UTF8(), byteIterator)
            return {
                switch codec.decode(&iterator) {
                case .scalarValue(let scalar): return scalar
                case .emptyInput: try onEmpty(); return nil
                case .error: throw Error._invalidUTF8()
                }
            }
        case .utf16BigEndian, .utf16, .unicode: // UTF16 & Unicode imply: follow the BOM and if it is not there, assume big endian.
            var (codec, iterator) = (Unicode.UTF16(), _Composer.UTF16BigEndian(iterator: byteIterator))
            return {
                switch codec.decode(&iterator) {
                case .scalarValue(let scalar): return scalar
                case .emptyInput:
                    try onEmpty()
                    if let error = iterator.error { throw error }
                    return nil
                case .error: throw Error._invalidUTF16()
                }
            }
        case .utf16LittleEndian:
            var (codec, iterator) = (Unicode.UTF16(), _Composer.UTF16LittleEndian(iterator: byteIterator))
            return {
                switch codec.decode(&iterator) {
                case .scalarValue(let scalar): return scalar
                case .emptyInput:
                    try onEmpty()
                    if let error = iterator.error { throw error }
                    return nil
                case .error: throw Error._invalidUTF16()
                }
            }
        case .utf32BigEndian, .utf32:   // UTF32 implies: follow the BOM and if it is not there, assume big endian.
            var (codec, iterator) = (Unicode.UTF32(), _Composer.UTF32BigEndian(iterator: byteIterator))
            return {
                switch codec.decode(&iterator) {
                case .scalarValue(let scalar): return scalar
                case .emptyInput:
                    try onEmpty()
                    if let error = iterator.error { throw error }
                    return nil
                case .error: throw Error._invalidUTF32()
                }
            }
        case .utf32LittleEndian:
            var (codec, iterator) = (Unicode.UTF32(), _Composer.UTF32LittleEndian(iterator: byteIterator))
            return {
                switch codec.decode(&iterator) {
                case .scalarValue(let scalar): return scalar
                case .emptyInput:
                    try onEmpty()
                    if let error = iterator.error { throw error }
                    return nil
                case .error: throw Error._invalidUTF32()
                }
            }
        default: throw Error._unsupported(encoding: encoding)
        }
    }
}

fileprivate extension CSVReader {
    /// The low-level buffer grouping the first bytes being used for BOM discovery with the all other bytes.
    private struct _IteratorBuffer<I>: IteratorProtocol where I:IteratorProtocol, I.Element==UInt8 {
        /// Input data iterator.
        private(set) var iterator: I
        /// Bytes received during BOM discovery process that are ready for interpretation.
        private(set) var bytes: [UInt8]
        
        mutating func next() -> UInt8? {
            guard self.bytes.isEmpty else { return self.bytes.removeFirst() }
            return self.iterator.next()
        }
    }

    /// The low-level buffer storing `chunks` of the CSV data.
    private final class _StreamBuffer: IteratorProtocol {
        /// The input stream providing the CSV data.
        private let _stream: InputStream
        /// Chunk data storage.
        private var _pointer: UnsafeMutableBufferPointer<UInt8>
        /// The last parsed byte position at the las chunk data storage position.
        private var (_index, _endIndex) = (0, 0)
        /// The status of this buffer.
        private(set) var status: Status = .active
        /// A buffer's lifecycle representation.
        enum Status { case active, finished, error(CSVError<CSVReader>) }
        
        /// Creates a new buffer witht the given input stream and the first bytes.
        /// - parameter bytes: The first bytes to be read.
        /// - parameter stream: Foundation's input stream reading a file or socket.
        /// - parameter chunk: The size of each reading step (e.g. 1024 bytes at a time).
        init(bytes: [UInt8], stream: InputStream, chunk: Int) {
            self._stream = stream
            precondition(chunk > bytes.count)
            self._pointer = .allocate(capacity: chunk)
            self._endIndex = self._pointer.initialize(from: bytes).1
        }
        
        deinit {
            self.destroy()
        }
        
        func next() -> UInt8? {
            if self._index >= self._endIndex {
                guard self.restock() else { return nil }
            }
            
            let result = self._pointer[self._index]
            self._index += 1
            return result
        }
        
        /// Ask the input stream for more data (in chunks).
        /// - returns: Indicates whether the restock process was successful.
        private func restock() -> Bool {
            guard case .active = self.status else { return false }
            
            switch self._stream.read(self._pointer.baseAddress!, maxLength: self._pointer.count) {
            case -1:
                self.destroy()
                let error = CSVReader.Error._inputStreamFailure(underlyingError: self._stream.streamError, status: self._stream.streamStatus)
                self.status = .error(error)
                return false
            case 0:
                self.destroy()
                return false
            case let count:
                (self._index, self._endIndex) = (0, count)
                return true
            }
        }
        
        /// Destroys the underlying buffer.
        private func destroy() {
            guard case .active = self.status else { return }
            self.status = .finished
            
            switch self._stream.streamStatus {
            case .notOpen, .closed: break
            default: self._stream.close()
            }
            
            self._pointer.deallocate()
            (self._index, self._endIndex) = (0, 0)
        }
    }
}

fileprivate extension CSVReader {
    /// Lists all available multibyte composers.
    private enum _Composer {
        /// Joins two bytes together into a single UTF16 big endian.
        struct UTF16BigEndian<I>: IteratorProtocol where I:IteratorProtocol, I.Element==UInt8 {
            /// The low-level iterator parsing through all the input bytes.
            private(set) var iterator: I
            /// If an error is produced, it will be stored here.
            private(set) var error: CSVError<CSVReader>? = nil
            /// Designated initializer providing the byte-by-byte iterator.
            init(iterator: I) { self.iterator = iterator }
            
            mutating func next() -> UTF16.CodeUnit? {
                guard let msb = self.iterator.next() else { return nil }
                guard let lsb = self.iterator.next() else {
                    self.error = Error._incompleteUTF16()
                    return nil
                }
                return [msb, lsb].withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: 1) {
                        UTF16.CodeUnit(bigEndian: $0.pointee)
                    }
                }
            }
        }
        
        /// Joins two bytes together into a single UTF16 little endian.
        struct UTF16LittleEndian<I>: IteratorProtocol where I:IteratorProtocol, I.Element==UInt8 {
            /// The low-level iterator parsing through all the input bytes.
            private(set) var iterator: I
            /// If an error is produced, it will be stored here.
            private(set) var error: CSVError<CSVReader>? = nil
            /// Designated initializer providing the byte-by-byte iterator.
            init(iterator: I) { self.iterator = iterator }
            
            mutating func next() -> UTF16.CodeUnit? {
                guard let lsb = self.iterator.next() else { return nil }
                guard let msb = self.iterator.next() else {
                    self.error = Error._incompleteUTF16()
                    return nil
                }
                return [lsb, msb].withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: 1) {
                        UTF16.CodeUnit(littleEndian: $0.pointee)
                    }
                }
            }
        }
        
        /// Joins four bytes together into a single UTF32 big endian.
        struct UTF32BigEndian<I>: IteratorProtocol where I:IteratorProtocol, I.Element==UInt8 {
            /// The low-level iterator parsing through all the input bytes.
            private(set) var iterator: I
            /// If an error is produced, it will be stored here.
            private(set) var error: CSVError<CSVReader>? = nil
            /// Designated initializer providing the byte-by-byte iterator.
            init(iterator: I) { self.iterator = iterator }
            
            mutating func next() -> UTF32.CodeUnit? {
                guard let msb = self.iterator.next() else { return nil }
                guard let ib2 = self.iterator.next(),
                      let ib3 = self.iterator.next(),
                      let lsb = self.iterator.next() else {
                    self.error = Error._incompleteUTF32()
                    return nil
                }
                return [msb, ib2, ib3, lsb].withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) {
                        UTF32.CodeUnit(bigEndian: $0.pointee)
                    }
                }
            }
        }
        
        /// Joins four bytes together into a single UTF32 little endian.
        struct UTF32LittleEndian<I>: IteratorProtocol where I:IteratorProtocol, I.Element==UInt8 {
            /// The low-level iterator parsing through all the input bytes.
            private(set) var iterator: I
            /// If an error is produced, it will be stored here.
            private(set) var error: CSVError<CSVReader>? = nil
            /// Designated initializer providing the byte-by-byte iterator.
            init(iterator: I) { self.iterator = iterator }
            
            mutating func next() -> UTF32.CodeUnit? {
                guard let msb = self.iterator.next() else { return nil }
                guard let ib2 = self.iterator.next(),
                      let ib3 = self.iterator.next(),
                      let lsb = self.iterator.next() else {
                    self.error = Error._incompleteUTF32()
                    return nil
                }
                return [lsb, ib3, ib2, msb].withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) {
                        UTF32.CodeUnit(littleEndian: $0.pointee)
                    }
                }
            }
        }
    }
}

fileprivate extension CSVReader.Error {
    /// Error raised when the given `String.Encoding` is not supported by the library.
    /// - parameter encoding: The desired byte representatoion.
    static func _unsupported(encoding: String.Encoding) -> CSVError<CSVReader> {
        .init(.invalidConfiguration,
              reason: "The given encoding is not yet supported by this library",
              help: "Contact the library maintainer",
              userInfo: ["Encoding": encoding])
    }
    /// Error raised when an input byte is an invalid ASCII character.
    /// - parameter byte: The byte being decoded from the input data.
    static func _invalidASCII(byte: UInt8) -> CSVError<CSVReader> {
        .init(.invalidInput,
              reason: "The decoded byte is not an ASCII character.",
              help: "Make sure the CSV only contains ASCII characters or select a different encoding (e.g. UTF8).",
              userInfo: ["Byte": byte])
    }
    /// Error raised when a UTF8 character cannot be constructed from some given input bytes.
    static func _invalidUTF8() -> CSVError<CSVReader> {
        .init(.invalidInput,
              reason: "Some input bytes couldn't be decoded as UTF8 characters",
              help: "Make sure the CSV only contains UTF8 characters or select a different encoding.")
    }
    /// Error raised when a UTF16 character cannot be constructed from some given input bytes.
    static func _invalidUTF16() -> CSVError<CSVReader> {
        .init(.invalidInput,
              reason: "Some input bytes couldn't be decoded as multibyte UTF16",
              help: "Make sure the CSV only contains UTF16 characters.")
    }
    /// Error raised when a UTF32 character cannot be constructed from some given input bytes.
    static func _invalidUTF32() -> CSVError<CSVReader> {
        .init(.invalidInput,
              reason: "Some input bytes couldn't be decoded as multibyte UTF32",
              help: "Make sure the CSV only contains UTF32 characters.")
    }
    /// Error raised when the input data cannot be accessed by an input stream.
    /// - parameter underlyingError: The error being raised from the Foundation's framework.
    /// - parameter status: The input stream status.
    static func _inputStreamFailure(underlyingError: Swift.Error?, status: Stream.Status) -> CSVError<CSVReader> {
        .init(.streamFailure, underlying: underlyingError,
              reason: "The input stream encountered an error while trying to read input bytes.",
              help: "Review the internal error and make sure you have access to the input data.",
              userInfo: ["Stream status": status])
    }
    /// Error raised when trying to retrieve two bytes from the input data, but only one was available.
    static func _incompleteUTF16() -> CSVError<CSVReader> {
        .init(.invalidInput,
              reason: "The last input UTF16 character is incomplete (only 1 byte was found when 2 were expected).",
              help: "Check the last UTF16 character of your input data/file.")
    }
    /// Error raised when trying to retrieve four bytes from the input data, but only one was available.
    static func _incompleteUTF32() -> CSVError<CSVReader> {
        .init(.invalidInput,
              reason: "The last input UTF32 character is incomplete (less than 4 bytes were found).",
              help: "Check the last UTF32 character of your input data/file.")
    }
}
