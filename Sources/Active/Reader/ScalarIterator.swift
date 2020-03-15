import Foundation

extension CSVReader {
    /// Iterates through all the `Unicode.Scalar`s within the input data.
    internal final class ScalarIterator {
        /// Closure where each time that is executed it generates a new scalar (from the input data), it throws an error, or returns `nil` indicating the end of the file.
        private typealias Decoder = () throws -> UnicodeScalar?
        /// The function requesting new data from the input.
        private let decoder: Decoder
        
        /// Creates a custom `Unicode.Scalar` iterator wrapping a simple scalar iterator (usually a `String.UnicodeScalarView.Iterator`).
        /// - parameter scalarIterator: Simple iterator returning a new `Unicode.Scalar` for each call of `next()`.
        init<I>(scalarIterator: I) where I:IteratorProtocol, I.Element==Unicode.Scalar {
            var iterator = scalarIterator
            self.decoder = { iterator.next() }
        }
        
        /// Creates a custom `Unicode.Scalar` iterator wraping a byte-by-byte iterator reading a data blob.
        /// - parameter iterator: Byte-by-byte iterator.
        /// - parameter encoding: The `String` encoding used to interpreted the read bytes.
        convenience init<I>(iterator: I, encoding: String.Encoding, firstBytes: [UInt8]) throws where I:IteratorProtocol, I.Element==UInt8 {
            let buffer = IteratorBuffer(bytes: firstBytes, iterator: iterator)
            try self.init(iterator: buffer, encoding: encoding, onEmpty: { })
        }
        
        /// Creates a custom `Unicode.Scalar` iterator wrapping an input stream providing byte data.
        /// - parameter stream: Input stream providing the input data.
        /// - parameter encoding: The `String` encoding used to interpreted the read bytes.
        /// - parameter chunk: The number of bytes read each the file is "touched".
        /// - parameter firstBytes: Bytes to be appended at the beginning of the byte buffer.
        convenience init(stream: InputStream, encoding: String.Encoding, chunk: Int, firstBytes: [UInt8]) throws {
            // For optimization purposes the CSV data is read in chunks and the bytes are stored in an intermediate buffer.
            let buffer = StreamBuffer(bytes: firstBytes, stream: stream, chunk: chunk)
            try self.init(iterator: buffer, encoding: encoding, onEmpty: { [unowned buffer] in
                guard case .error(let error) = buffer.status else { return }
                throw error
            })
        }
        
        /// Creates a custom `Unicode.Scalar` iterator wraping a byte-by-byte iterator.
        /// - parameter iterator: Byte-by-byte iterator.
        /// - parameter encoding: The `String` encoding used to interpreted the read bytes.
        /// - parameter onEmpty: Closure used to check whether the "no-more-bytes" received event is actually that there is no bytes or there was a low-layer error.
        private init<I>(iterator: I, encoding: String.Encoding, onEmpty: @escaping () throws -> Void) throws where I:IteratorProtocol, I.Element==UInt8 {
            switch encoding {
            case .ascii:
                var iterator = iterator
                self.decoder = {
                    guard let byte = iterator.next() else { try onEmpty(); return nil }
                    guard Unicode.ASCII.isASCII(byte) else { throw Error.invalidASCII(byte: byte) }
                    return Unicode.ASCII.decode(.init(byte))
                }
            case .utf8:
                var (codec, iterator) = (Unicode.UTF8(), iterator)
                self.decoder = {
                    switch codec.decode(&iterator) {
                    case .scalarValue(let scalar): return scalar
                    case .emptyInput: try onEmpty(); return nil
                    case .error: throw Error.invalidUTF8()
                    }
                }
            case .utf16BigEndian, .utf16, .unicode: // UTF16 & Unicode imply: follow the BOM and if it is not there, assume big endian.
                var (codec, iterator) = (Unicode.UTF16(), Composer.UTF16BigEndian(iterator: iterator))
                self.decoder = {
                    switch codec.decode(&iterator) {
                    case .scalarValue(let scalar): return scalar
                    case .emptyInput:
                        try onEmpty()
                        if let error = iterator.error { throw error }
                        return nil
                    case .error: throw CSVReader.Error.invalidMultibyteUTF()
                    }
                }
            case .utf16LittleEndian:
                var (codec, iterator) = (Unicode.UTF16(), Composer.UTF16LittleEndian(iterator: iterator))
                self.decoder = {
                    switch codec.decode(&iterator) {
                    case .scalarValue(let scalar): return scalar
                    case .emptyInput:
                        try onEmpty()
                        if let error = iterator.error { throw error }
                        return nil
                    case .error: throw CSVReader.Error.invalidMultibyteUTF()
                    }
                }
            case .utf32BigEndian, .utf32:   // UTF32 implies: follow the BOM and if it is not there, assume big endian.
                var (codec, iterator) = (Unicode.UTF32(), Composer.UTF32BigEndian(iterator: iterator))
                self.decoder = {
                    switch codec.decode(&iterator) {
                    case .scalarValue(let scalar): return scalar
                    case .emptyInput:
                        try onEmpty()
                        if let error = iterator.error { throw error }
                        return nil
                    case .error: throw CSVReader.Error.invalidMultibyteUTF()
                    }
                }
            case .utf32LittleEndian:
                var (codec, iterator) = (Unicode.UTF32(), Composer.UTF32LittleEndian(iterator: iterator))
                self.decoder = {
                    switch codec.decode(&iterator) {
                    case .scalarValue(let scalar): return scalar
                    case .emptyInput:
                        try onEmpty()
                        if let error = iterator.error { throw error }
                        return nil
                    case .error: throw CSVReader.Error.invalidMultibyteUTF()
                    }
                }
            default:
                throw CSVReader.Error(.invalidInput, reason: "The given encoding is not yet supported by this library", help: "Contact the library maintainer", userInfo: ["Encoding": encoding])
            }
        }
        
        /// Advances to the next element and returns it, or `nil` if no next element exists. In case there was an error extracting an element the function may throw.
        func next() throws -> Unicode.Scalar? {
            try self.decoder()
        }
    }
}

fileprivate extension CSVReader.ScalarIterator {
    /// The low-level buffer grouping the first bytes being used for BOM discovery with the all other bytes.
    private struct IteratorBuffer<I>: IteratorProtocol where I:IteratorProtocol, I.Element==UInt8 {
        /// Bytes received during BOM discovery process that are ready for interpretation.
        private(set) var bytes: [UInt8]
        /// Input data iterator.
        private(set) var iterator: I
        
        mutating func next() -> UInt8? {
            guard self.bytes.isEmpty else { return self.bytes.removeFirst() }
            return self.iterator.next()
        }
    }

    /// The low-level buffer storing `chunks` of the CSV data.
    private final class StreamBuffer: IteratorProtocol {
        /// The input stream providing the CSV data.
        private let stream: InputStream
        /// Chunk data storage.
        private var pointer: UnsafeMutableBufferPointer<UInt8>
        /// The last parsed byte position at the las chunk data storage position.
        private var (index, endIndex) = (0, 0)
        /// The status of this buffer.
        private(set) var status: Status = .active
        
        enum Status {
            case active, finished, error(CSVReader.Error)
        }
        
        /// Creates a new buffer witht he given input stream and the first bytes.
        init(bytes: [UInt8], stream: InputStream, chunk: Int) {
            self.stream = stream
            precondition(chunk > 0)
            self.pointer = .allocate(capacity: chunk)
            self.endIndex = self.pointer.initialize(from: bytes).1
        }
        
        deinit {
            self.destroy()
        }
        
        /// Destroys the underlying buffer.
        private func destroy() {
            guard case .active = self.status else { return }
            self.status = .finished
            
            switch self.stream.streamStatus {
            case .notOpen, .closed: break
            default: self.stream.close()
            }
            
            self.pointer.deallocate()
            (self.index, self.endIndex) = (0, 0)
        }
        
        /// Ask the input stream for more data.
        /// - returns: Indicates whether the restock process was successful.
        private func restock() -> Bool {
            guard case .active = self.status else { return false }
            
            switch self.stream.read(self.pointer.baseAddress!, maxLength: self.pointer.count) {
            case -1:
                self.destroy()
                self.status = .error(.init(.streamFailure, underlying: self.stream.streamError,
                                          reason: "The input stream encountered an error while trying to read the first bytes.",
                                          help: "Review the internal error and make sure you have access to the input data.",
                                          userInfo: ["Status": self.stream.streamStatus]))
                return false
            case 0:
                self.destroy()
                return false
            case let count:
                (self.index, self.endIndex) = (0, count)
                return true
            }
        }
        
        func next() -> UInt8? {
            if self.index >= self.endIndex {
                guard self.restock() else { return nil }
            }
            
            let result = self.pointer[self.index]
            self.index += 1
            return result
        }
    }
}

fileprivate extension CSVReader {
    /// Lists all available multibyte composers.
    private enum Composer {
        /// Joins two bytes together into a single UTF16 big endian.
        struct UTF16BigEndian<I>: IteratorProtocol where I:IteratorProtocol, I.Element==UInt8 {
            /// The low-level iterator parsing through all the input bytes.
            private(set) var iterator: I
            /// If an error is produced, it will be stored here.
            private(set) var error: CSVReader.Error? = nil
            /// Designated initializer providing the byte-by-byte iterator.
            init(iterator: I) { self.iterator = iterator }
            
            mutating func next() -> UTF16.CodeUnit? {
                guard let msb = iterator.next() else { return nil }
                guard let lsb = iterator.next() else {
                    self.error = CSVReader.Error(.invalidInput, reason: "An error occurred mapping bytes into UTF16 characters.", help: "Check the last UTF16 character of your input data/file.")
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
            private(set) var error: CSVReader.Error? = nil
            /// Designated initializer providing the byte-by-byte iterator.
            init(iterator: I) { self.iterator = iterator }
            
            mutating func next() -> UTF16.CodeUnit? {
                guard let lsb = iterator.next() else { return nil }
                guard let msb = iterator.next() else {
                    self.error = CSVReader.Error(.invalidInput, reason: "An error occurred mapping bytes into UTF16 characters.", help: "Check the last UTF16 character of your input data/file.")
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
            private(set) var error: CSVReader.Error? = nil
            /// Designated initializer providing the byte-by-byte iterator.
            init(iterator: I) { self.iterator = iterator }
            
            mutating func next() -> UTF32.CodeUnit? {
                guard let msb = iterator.next() else { return nil }
                guard let ib2 = iterator.next(),
                      let ib3 = iterator.next(),
                      let lsb = iterator.next() else {
                    self.error = CSVReader.Error(.invalidInput, reason: "An error occurred mapping bytes into UTF32 characters.", help: "Check the last UTF32 character of your input data/file.")
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
            private(set) var error: CSVReader.Error? = nil
            /// Designated initializer providing the byte-by-byte iterator.
            init(iterator: I) { self.iterator = iterator }
            
            mutating func next() -> UTF32.CodeUnit? {
                guard let msb = iterator.next() else { return nil }
                guard let ib2 = iterator.next(),
                      let ib3 = iterator.next(),
                      let lsb = iterator.next() else {
                    self.error = CSVReader.Error(.invalidInput, reason: "An error occurred mapping bytes into UTF32 characters.", help: "Check the last UTF32 character of your input data/file.")
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
