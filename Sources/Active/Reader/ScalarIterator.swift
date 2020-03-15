import Foundation

extension CSVReader {
    /// Iterates through all the `Unicode.Scalar`s within the input data.
    internal final class ScalarIterator {
        /// The function requesting new data from the input.
        private var decoder: Decoder
        /// Designated initializer wrapping around a scalar iterator (e.g. `String.UnicodeScalarView.Iterator`).
        init<I>(scalarIterator: I) where I:IteratorProtocol, I.Element==Unicode.Scalar {
            var iterator = scalarIterator
            self.decoder = { iterator.next() }
        }
        /// Designated initializer decoding byte-by-byte a data blob represented by the byte iterator.
        init<I>(dataIterator: I, encoding: String.Encoding) throws where I:IteratorProtocol, I.Element==UInt8 {
            switch encoding {
            case .ascii:
                var iterator = dataIterator
                self.decoder = {
                    guard let byte = iterator.next() else { return nil }
                    guard Unicode.ASCII.isASCII(byte) else { throw Error.invalidASCII(byte: byte) }
                    return Unicode.ASCII.decode(.init(byte))
                }
            case .utf8:
                var iterator = dataIterator
                var codec = Unicode.UTF8()
                self.decoder = {
                    switch codec.decode(&iterator) {
                    case .scalarValue(let scalar): return scalar
                    case .emptyInput: return nil
                    case .error: throw Error.invalidUTF8()
                    }
                }
            case .utf16BigEndian, .utf16, .unicode: // UTF16 & Unicode imply: follow the BOM and if it is not there, assume big endian.
                self.decoder = Self.makeMultiByteDecoder(codec: Unicode.UTF16(), iterator: Composer.UTF16BigEndian(iterator: dataIterator))
            case .utf16LittleEndian:
                self.decoder = Self.makeMultiByteDecoder(codec: Unicode.UTF16(), iterator: Composer.UTF16LittleEndian(iterator: dataIterator))
            case .utf32BigEndian, .utf32:   // UTF32 implies: follow the BOM and if it is not there, assume big endian.
                self.decoder = Self.makeMultiByteDecoder(codec: Unicode.UTF32(), iterator: Composer.UTF32BigEndian(iterator: dataIterator))
            case .utf32LittleEndian:
                self.decoder = Self.makeMultiByteDecoder(codec: Unicode.UTF32(), iterator: Composer.UTF32LittleEndian(iterator: dataIterator))
            default:
                throw CSVReader.Error(.invalidInput, reason: "The given encoding is not yet supported by this library", help: "Contact the library maintainer", userInfo: ["Encoding": encoding])
            }
        }
        
        init(stream: InputStream, encoding: String.Encoding) throws {
            #warning("Implement me")
            fatalError()
        }
        
        func next() throws -> Unicode.Scalar? {
            try self.decoder()
        }
    }
}

fileprivate extension CSVReader.ScalarIterator {
    /// Closure where each time that is executed it generates a new scalar (from the input data), it throws an error, or returns `nil` indicating the end of the file.
    private typealias Decoder = () throws -> UnicodeScalar?
    /// The scalar's iterator decoder composing multiple bytes into a `CodeUnit` and then mapping several code units (if necessary) into a `Unicode.Scalar`.
    private static func makeMultiByteDecoder<C,I>(codec: C, iterator: I) -> Decoder where C:UnicodeCodec, I:ComposerIterator, I.Element==C.CodeUnit {
        var codec = codec
        var iterator = iterator
        return {
            switch codec.decode(&iterator) {
            case.scalarValue(let scalar): return scalar
            case .emptyInput:
                guard let error = iterator.error else { return nil }
                throw error
            case .error: throw CSVReader.Error.invalidMultibyteUTF()
            }
        }
    }
}

/// Protocol for all multibyte to Unicode iterator.
fileprivate protocol ComposerIterator: IteratorProtocol {
    /// The low-level iterator parsing through all the input bytes.
    associatedtype Iterator: IteratorProtocol where Iterator.Element==UInt8
    /// Designated initializer providing the byte-by-byte iterator.
    init(iterator: Iterator)
    /// If an error is produced, it will be stored here.
    var error: CSVReader.Error? { get }
}

extension CSVReader {
    /// Lists all available multibyte composers.
    internal enum Composer {
        /// Joins two bytes together into a single UTF16 big endian.
        struct UTF16BigEndian<I>: ComposerIterator where I:IteratorProtocol, I.Element==UInt8 {
            /// The low-level iterator parsing through all the input bytes.
            private(set) var iterator: I
            /// If an error is produced, it will be stored here.
            private(set) var error: CSVReader.Error? = nil
            /// Designated initializer providing the byte-by-byte iterator.
            init(iterator: I) { self.iterator = iterator }
            
            mutating func next() -> UTF16.CodeUnit? {
                guard let msb = iterator.next() else { return nil }
                guard let lsb = iterator.next() else {
                    self.error = CSVReader.Error(.invalidInput,
                                                 reason: "An error occurred mapping bytes into UTF16 characters.",
                                                 help: "Check the last UTF16 character of your input data/file.")
                    return nil
                }
                return [msb, lsb].withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: 1) {
                        UTF16.CodeUnit(bigEndian: $0.pointee)
                    }
                }
            }
        }
        
        /// Joins two bytes together into a single UTF16 big endian.
        struct UTF16LittleEndian<I>: ComposerIterator where I:IteratorProtocol, I.Element==UInt8 {
            /// The low-level iterator parsing through all the input bytes.
            private(set) var iterator: I
            /// If an error is produced, it will be stored here.
            private(set) var error: CSVReader.Error? = nil
            /// Designated initializer providing the byte-by-byte iterator.
            init(iterator: I) { self.iterator = iterator }
            
            mutating func next() -> UTF16.CodeUnit? {
                guard let lsb = iterator.next() else { return nil }
                guard let msb = iterator.next() else {
                    self.error = CSVReader.Error(.invalidInput,
                                                 reason: "An error occurred mapping bytes into UTF16 characters.",
                                                 help: "Check the last UTF16 character of your input data/file.")
                    return nil
                }
                return [lsb, msb].withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: 1) {
                        UTF16.CodeUnit(littleEndian: $0.pointee)
                    }
                }
            }
        }
        
        /// Joins two bytes together into a single UTF16 big endian.
        struct UTF32BigEndian<I>: ComposerIterator where I:IteratorProtocol, I.Element==UInt8 {
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
                        self.error = CSVReader.Error(.invalidInput,
                                                     reason: "An error occurred mapping bytes into UTF32 characters.",
                                                     help: "Check the last UTF32 character of your input data/file.")
                        return nil
                }
                return [msb, ib2, ib3, lsb].withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) {
                        UTF32.CodeUnit(bigEndian: $0.pointee)
                    }
                }
            }
        }
        
        /// Joins two bytes together into a single UTF16 big endian.
        struct UTF32LittleEndian<I>: ComposerIterator where I:IteratorProtocol, I.Element==UInt8 {
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
                        self.error = CSVReader.Error(.invalidInput,
                                                     reason: "An error occurred mapping bytes into UTF32 characters.",
                                                     help: "Check the last UTF32 character of your input data/file.")
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
