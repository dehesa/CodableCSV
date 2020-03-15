import Foundation

extension String.Encoding {
    /// Starts parsing the CSV file to try to figure out its encoding.
    ///
    /// This initializer looks for the Byte Order Mark (or [BOM](https://en.wikipedia.org/wiki/Byte_order_mark)) at the beginning of the file.
    /// - parameter iterator: The input data byte iterator.
    /// - parameter unusedBytes: The input data bytes that has been read, but are not part from the BOM.
    internal init?<I>(iterator: inout I, unusedBytes: inout [UInt8]) throws where I:IteratorProtocol, I.Element==UInt8 {
        // 1. Gather all BOMs and count what is the maximum number of bytes to represent any of them.
        let allEncodings = BOM.allCases
        let maxChars = allEncodings.reduce(0) { max($0, $1.value.count) }
        
        // 2. Retrieve all bytes from the iterator.
        assert(unusedBytes.isEmpty)
        for _ in 0..<maxChars {
            guard let char = iterator.next() else { break }
            unusedBytes.append(char)
        }
        
        // 3. If the iterator did provide less than all required bytes, filter the encodings.
        let retrievedChars = unusedBytes.count
        // Support for empty files.
        guard !unusedBytes.isEmpty else { return nil }
        let encodings = (retrievedChars < maxChars) ? allEncodings.filter { $0.value.count <= retrievedChars } : allEncodings
        
        // 4. Select the encoding that matches.
        for (encoding, bom) in encodings {
            guard bom.elementsEqual(unusedBytes.prefix(bom.count)) else { continue }
            unusedBytes.removeFirst(bom.count)
            self = encoding
        }
        // 5. If no encoding is matched, no encoding is returned.
        return nil
    }
    
    /// Starts parsing the CSV file to try to figure out its encoding.
    ///
    /// This initializer looks for the Byte Order Mark (or [BOM](https://en.wikipedia.org/wiki/Byte_order_mark)) at the beginning of the file.
    /// - parameter stream:
    /// - parameter unusedBytes: The input data bytes that has been read, but are not part from the BOM.
    internal init?(stream: InputStream, unusedBytes: inout [UInt8]) throws {
        // 1. Gather all BOMs and count what is the maximum number of bytes to represent any of them.
        let allEncodings = BOM.allCases
        let maxChars = allEncodings.reduce(0) { max($0, $1.value.count) }
        
        // 2. Retrieve all bytes from the iterator.
        assert(unusedBytes.isEmpty)
        switch stream.read(&unusedBytes, maxLength: maxChars) {
        case 0: return nil
        case -1: throw CSVReader.Error(.streamFailure, underlying: stream.streamError,
                                       reason: "The input stream encountered an error while trying to read the first bytes.",
                                       help: "Review the internal error and make sure you have access to the input data.",
                                       userInfo: ["Status":stream.streamStatus])
        default: break
        }
        
        // 3. If the iterator did provide less than all required bytes, filter the encodings.
        let retrievedChars = unusedBytes.count
        // Support for empty files.
        guard !unusedBytes.isEmpty else { return nil }
        let encodings = (retrievedChars < maxChars) ? allEncodings.filter { $0.value.count <= retrievedChars } : allEncodings
        
        // 4. Select the encoding that matches.
        for (encoding, bom) in encodings {
            guard bom.elementsEqual(unusedBytes.prefix(bom.count)) else { continue }
            unusedBytes.removeFirst(bom.count)
            self = encoding
        }
        // 5. If no encoding is matched, no encoding is returned.
        return nil
    }
}

extension String.Encoding {
    /// Select the appropriate encoding depending on the `String` encoding provided by the user and the encoding inferred from the Byte Order Marker.
    /// - parameter provided: The user provided `String` encoding.
    /// - parameter inferred: The `String` encoding inferred from the data Byte Order Marker.
    /// - throws: `CSVReader.Error` exclusively.
    /// - returns: The appropriate `String.Encoding` matching from the provided and inferred values.
    internal static func selectFrom(provided: String.Encoding?, inferred: String.Encoding?) throws -> String.Encoding {
        switch (provided, inferred) {
        case (nil, nil): return .utf8
        case (nil, let rhs?): return rhs
        case (let lhs?, nil): return lhs
        case (let lhs?, let rhs?) where lhs == rhs: return lhs
        case (let lhs?, let rhs?): // Only executes when lhs != rhs
            switch (lhs, rhs) {
            case (.utf16, .utf16LittleEndian),
                 (.utf16, .utf16BigEndian),
                 (.utf32, .utf32LittleEndian),
                 (.utf32, .utf32BigEndian),
                 (.unicode, .utf16LittleEndian),
                 (.unicode, .utf16BigEndian): return rhs
            default:
                throw CSVReader.Error(.invalidInput,
                                      reason: "The encoding passed in the configuration doesn't match the Byte Order Mark (BOM) from the input data",
                                      help: "Set the appropriate encoding for the reader configuration or don't set any at all (pass nil)",
                                      userInfo: ["Provided encoding": lhs, "Data BOM encoding": rhs])
            }
        }
    }
}

extension String.Encoding {
    /// Tries to map previously read bytes into `Unicode.Scalar` and if more bytes are needed, it requests them from the input data iterator.
    /// - parameter bytes: The bytes being parsed for BOM detection, but are no part of the BOM itself.
    /// - parameter iterator: The iterator reading the CSV byte-by-byte.
    internal func consume<I>(bytes: [UInt8], iterator: inout I) throws -> [Unicode.Scalar] where I:IteratorProtocol, I.Element==UInt8 {
        var result: [Unicode.Scalar] = []
        guard !bytes.isEmpty else { return result }
        
        switch self {
        case .ascii:
            result = try bytes.map {
                guard Unicode.ASCII.isASCII($0) else { throw CSVReader.Error.invalidASCII(byte: $0) }
                return Unicode.ASCII.decode(.init($0))
            }
        case .utf8:
            var codec = Unicode.UTF8()
            var wrapper = Amalgamation(bytes: bytes, iterator: iterator)
            while !wrapper.bytes.isEmpty {
                switch codec.decode(&wrapper) {
                case .scalarValue(let scalar): result.append(scalar)
                case .emptyInput: break
                case .error: throw CSVReader.Error.invalidUTF8()
                }
                iterator = wrapper.iterator
            }
        case .utf16BigEndian, .utf16, .unicode: // UTF16 & Unicode imply: follow the BOM and if it is not there, assume big endian.
            var codec = Unicode.UTF16()
            var composer = CSVReader.Composer.UTF16BigEndian(iterator: Amalgamation(bytes: bytes, iterator: iterator))
            loop: while !composer.iterator.bytes.isEmpty {
                switch codec.decode(&composer) {
                case .scalarValue(let scalar): result.append(scalar)
                case .emptyInput:
                    guard let error = composer.error else { break loop }
                    throw error
                case .error: throw CSVReader.Error.invalidMultibyteUTF()
                }
                iterator = composer.iterator.iterator
            }
        case .utf16LittleEndian:
            var codec = Unicode.UTF16()
            var wrapper = Amalgamation(bytes: bytes, iterator: iterator)
            while !wrapper.bytes.isEmpty {
                fatalError()
                iterator = wrapper.iterator
            }
        case .utf32BigEndian, .utf32:   // UTF32 implies: follow the BOM and if it is not there, assume big endian.
            var codec = Unicode.UTF32()
            var wrapper = Amalgamation(bytes: bytes, iterator: iterator)
            while !wrapper.bytes.isEmpty {
                fatalError()
                iterator = wrapper.iterator
            }
        case .utf32LittleEndian:
            var codec = Unicode.UTF32()
            var wrapper = Amalgamation(bytes: bytes, iterator: iterator)
            while !wrapper.bytes.isEmpty {
                fatalError()
                iterator = wrapper.iterator
            }
        default:
            throw CSVReader.Error(.invalidInput,
                                  reason: "The given encoding is not yet supported by this library",
                                  help: "Contact the library maintainer",
                                  userInfo: ["Encoding": self])
        }
        
        return result
    }
    
    private struct Amalgamation<I>: IteratorProtocol where I:IteratorProtocol, I.Element==UInt8 {
        private(set) var bytes: [UInt8]
        private(set) var iterator: I
        
        mutating func next() -> UInt8? {
            guard self.bytes.isEmpty else { return self.bytes.removeFirst() }
            return self.iterator.next()
        }
    }
    
    /// Tries to map previously read bytes into `Unicode.Scalar` and if more bytes are needed, it requests them from the input data iterator.
    /// - parameter bytes: The bytes being parsed for BOM detection, but are no part of the BOM itself.
    /// - parameter iterator: The iterator reading the CSV byte-by-byte.
    internal func consume(bytes: [UInt8], stream: InputStream) throws -> [Unicode.Scalar] {
        guard !bytes.isEmpty else { return [] }
        
        switch self {
        case .ascii:
            return try bytes.map {
                guard Unicode.ASCII.isASCII($0) else { throw CSVReader.Error.invalidASCII(byte: $0) }
                return Unicode.ASCII.decode(.init($0))
            }
        default:
            throw CSVReader.Error(.invalidInput,
                                  reason: "The given encoding is not yet supported by this library",
                                  help: "Contact the library maintainer",
                                  userInfo: ["Encoding": self])
        }
        
        #warning("Implement me")
        fatalError()
    }
}
