import Foundation

internal extension CSVWriter {
    /// Closure where each time that is executed a scalar will be stored on the final output.
    typealias ScalarEncoder = (Unicode.Scalar) throws -> Void
    
    /// Creates an encoder that take a `Unicode.Scalar` and store the correct byte representation on the appropriate place.
    /// - parameter outputStream: Output stream receiving the encoded data.
    /// - parameter encoding: The string encoding being used for the external representation.
    /// - parameter firstBytes: Bytes to be preppended at the beggining of the stream.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    /// - returns: An encoder closure writing bytes in the provided stream with the given string encoding.
    static func makeEncoder(from outputStream: OutputStream, encoding: String.Encoding, firstBytes: [UInt8]) throws -> ScalarEncoder {
        guard case .open = outputStream.streamStatus else {
            throw Error._unopenStream(status: outputStream.streamStatus, error: outputStream.streamError)
        }
        
        let stream = Unmanaged<OutputStream>.passUnretained(outputStream)
        
        if !firstBytes.isEmpty {
            try CSVWriter._streamWrite(on: stream, bytes: firstBytes, count: firstBytes.count)
        }
        
        switch encoding {
        case .ascii:
            return { (scalar) in
                guard var byte = Unicode.ASCII.encode(scalar)?.first else { throw Error._invalidASCII(scalar: scalar) }
                try CSVWriter._streamWrite(on: stream, bytes: &byte, count: 1)
            }
        case .utf8:
            return { (scalar) in
                guard var iterator = Unicode.UTF8.encode(scalar)?.makeIterator() else { throw Error._invalidUTF8(scalar: scalar) }
                
                var bytes = (iterator.next()!, UInt8.zero, UInt8.zero, UInt8.zero)
                var count: Int = 1
                
                try withUnsafeMutableBytes(of: &bytes) {
                    let ptr = $0.baseAddress.unsafelyUnwrapped.assumingMemoryBound(to: UInt8.self)
                    
                    while let byte = iterator.next() {
                        (ptr + count).pointee = byte
                        count &+= 1
                    }
                    
                    try CSVWriter._streamWrite(on: stream, bytes: ptr, count: count)
                }
            }
        case .utf16BigEndian, .utf16, .unicode: // UTF16 & Unicode imply: follow the BOM and if it is not there, assume big endian.
            return { (scalar) in
                guard let tmp = Unicode.UTF16.encode(scalar) else { throw Error._invalidUTF16(scalar: scalar) }
                let bytes = tmp.flatMap {
                    [UInt8(truncatingIfNeeded: $0 >> 8),
                     UInt8(truncatingIfNeeded: $0)]
                }
                try CSVWriter._streamWrite(on: stream, bytes: bytes, count: bytes.count)
            }
        case .utf16LittleEndian:
            return { (scalar) in
                guard let tmp = Unicode.UTF16.encode(scalar) else { throw Error._invalidUTF16(scalar: scalar) }
                let bytes = tmp.flatMap {
                    [UInt8(truncatingIfNeeded: $0),
                     UInt8(truncatingIfNeeded: $0 >> 8)]
                }
                try CSVWriter._streamWrite(on: stream, bytes: bytes, count: bytes.count)
            }
        case .utf32BigEndian, .utf32:
            return { (scalar) in
                guard let tmp = Unicode.UTF32.encode(scalar) else { throw Error._invalidUTF32(scalar: scalar) }
                let bytes = tmp.flatMap {
                    [UInt8(truncatingIfNeeded: $0 >> 24),
                     UInt8(truncatingIfNeeded: $0 >> 16),
                     UInt8(truncatingIfNeeded: $0 >> 8),
                     UInt8(truncatingIfNeeded: $0)]
                }
                try CSVWriter._streamWrite(on: stream, bytes: bytes, count: bytes.count)
            }
        case .utf32LittleEndian:
            return { (scalar) in
                guard let tmp = Unicode.UTF32.encode(scalar) else { throw Error._invalidUTF32(scalar: scalar) }
                let bytes = tmp.flatMap {
                    [UInt8(truncatingIfNeeded: $0),
                     UInt8(truncatingIfNeeded: $0 >> 8),
                     UInt8(truncatingIfNeeded: $0 >> 16),
                     UInt8(truncatingIfNeeded: $0 >> 24)]
                }
                try CSVWriter._streamWrite(on: stream, bytes: bytes, count: bytes.count)
            }
        case .shiftJIS:
            return { (scalar) in
                // - todo: Performance for Shift JIS is pretty bad. Figure out how to encode a Unicode scalar to Shift JIS directly without going through String -> Data -> [UInt8]
                guard let tmp = String(scalar).data(using: .shiftJIS) else { throw Error._invalidShiftJIS(scalar: scalar) }
                try tmp.withUnsafeBytes {
                    let count = $0.count
                    let ptr = $0.baseAddress.unsafelyUnwrapped.assumingMemoryBound(to: UInt8.self)
                    try CSVWriter._streamWrite(on: stream, bytes: ptr, count: count)
                }
            }
        default: throw Error._unsupported(encoding: encoding)
        }
    }
}

fileprivate extension CSVWriter {
    /// Writes on the stream the given bytes.
    /// - precondition: `count` is always greater than zero.
    /// - parameter stream: The output stream accepting the writes.
    /// - parameter bytes: The actual bytes to be written.
    /// - parameter count: The number of bytes within `bytes`.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    private static func _streamWrite(on stream: Unmanaged<OutputStream>, bytes: UnsafePointer<UInt8>, count: Int) throws {
        let attempts = 2
        var (distance, remainingAttempts) = (0, attempts)
        
        try stream._withUnsafeGuaranteedRef {
            repeat {
                let written = $0.write(bytes.advanced(by: distance), maxLength: count - distance)
                
                if written > 0 {
                    distance += written
                } else if written == 0 {
                    remainingAttempts -= 1
                    guard remainingAttempts > 0 else {
                        throw Error._streamEmptyWrite(error: $0.streamError, status: $0.streamStatus, numAttempts: attempts)
                    }
                    continue
                } else {
                    throw Error._streamFailed(error: $0.streamError, status: $0.streamStatus)
                }
            } while distance < count
        }
    }
}

// MARK: -

fileprivate extension CSVWriter.Error {
    /// Error raised when the requested `String.Encoding` is not supported by the library.
    /// - parameter encoding: The desired byte representatoion.
    static func _unsupported(encoding: String.Encoding) -> CSVError<CSVWriter> {
        .init(.invalidConfiguration,
              reason: "The given encoding is not yet supported by this library",
              help: "Contact the library maintainer",
              userInfo: ["Encoding": encoding])
    }
    /// Error raised when a Unicode scalar is an invalid ASCII character.
    /// - parameter byte: The byte being decoded from the input data.
    static func _invalidASCII(scalar: Unicode.Scalar) -> CSVError<CSVWriter> {
        .init(.invalidInput,
              reason: "The Unicode Scalar is not an ASCII character.",
              help: "Make sure the CSV only contains ASCII characters or select a different encoding (e.g. UTF8).",
              userInfo: ["Unicode scalar": scalar])
    }
    /// Error raised when a UTF8 character cannot be constructed from a Unicode scalar value.
    static func _invalidUTF8(scalar: Unicode.Scalar) -> CSVError<CSVWriter> {
        .init(.invalidInput,
              reason: "The Unicode Scalar couldn't be encoded to UTF8 characters",
              help: "Make sure the CSV only contains UTF8 characters or select a different encoding.",
              userInfo: ["Unicode scalar": scalar])
    }
    /// Error raised when a UTF16 character cannot be constructed from a Unicode scalar value.
    static func _invalidUTF16(scalar: Unicode.Scalar) -> CSVError<CSVWriter> {
        .init(.invalidInput,
              reason: "The Unicode Scalar couldn't be encoded to multibyte UTF16",
              help: "Make sure the CSV only contains UTF16 characters.",
              userInfo: ["Unicode scalar": scalar])
    }
    /// Error raised when a UTF32 character cannot be constructed from a Unicode scalar value.
    static func _invalidUTF32(scalar: Unicode.Scalar) -> CSVError<CSVWriter> {
        .init(.invalidInput,
              reason: "The Unicode Scalar couldn't be encoded to multibyte UTF32",
              help: "Make sure the CSV only contains UTF32 characters.",
              userInfo: ["Unicode scalar": scalar])
    }
    /// Error raised when a Shift-JIS character cannot be constructed from a Unicode scalar value.
    static func _invalidShiftJIS(scalar: Unicode.Scalar) -> CSVError<CSVWriter> {
        .init(.invalidInput,
              reason: "The Unicode Scalar couldn't be encoded to multibyte Shift-JIS",
              help: "Make sure the CSV only contains Shift-JIS characters.",
              userInfo: ["Unicode scalar": scalar])
    }
    /// Error raised when the output stream failed to write some bytes.
    static func _streamFailed(error: Swift.Error?, status: Stream.Status) -> CSVError<CSVWriter> {
        .init(.streamFailure, underlying: error,
              reason: "The output stream encountered an error while trying to write encoded bytes",
              help: "Review the underlying error and make sure you have access to the output data (if it is a file)",
              userInfo: ["Stream status": status])
    }
    /// Error raised when the output stream hasn't failed, but it hasn't writen anything either for `numAttempts` attempts.
    static func _streamEmptyWrite(error: Swift.Error?, status: Stream.Status, numAttempts: Int) -> CSVError<CSVWriter> {
        .init(.streamFailure, underlying: error,
              reason: "Several attempts were made to write on the stream, but they were unsuccessful.",
              help: "Review the underlying error (if any) and try again.",
              userInfo: ["Stream status": status, "Attempts": numAttempts])
    }
    /// Error raised when the output stream is expected to be opened, but it is not.
    static func _unopenStream(status: Stream.Status, error: Swift.Error?) -> CSVError<CSVWriter> {
        .init(.streamFailure, underlying: error,
              reason: "The output stream is not open.",
              help: "Check you have priviledge to open the output stream.",
              userInfo: ["Stream status": status])
    }
}
