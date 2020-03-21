import Foundation

internal extension CSVWriter {
    /// Closure where each time that is executed a scalar will be stored on the final output.
    typealias ScalarEncoder = (Unicode.Scalar) throws -> Void
    
    /// Creates an encoder that take a `Unicode.Scalar` and store the correct byte representation on the appropriate place.
    /// - parameter stream: Output stream receiving the encoded data.
    /// - parameter encoding: The string encoding being used for the external representation.
    /// - parameter firstBytes: Bytes to be preppended at the beggining of the stream.
    static func makeEncoder(from stream: OutputStream, encoding: String.Encoding, firstBytes: [UInt8]) throws -> ScalarEncoder {
        if !firstBytes.isEmpty {
            try CSVWriter.lowlevelWriter(on: stream, bytes: firstBytes, count: firstBytes.count)
        }
        
        switch encoding {
        case .ascii:
            return { [unowned stream] (scalar) in
                guard var byte = Unicode.ASCII.encode(scalar)?.first else { throw Error.invalidASCII(scalar: scalar) }
                try CSVWriter.lowlevelWriter(on: stream, bytes: &byte, count: 1)
            }
        case .utf8:
            return { [unowned stream] (scalar) in
                guard let bytes = Unicode.UTF8.encode(scalar),
                      let _ = try bytes.withContiguousStorageIfAvailable({ try CSVWriter.lowlevelWriter(on: stream, bytes: $0.baseAddress!, count: bytes.count) }) else {
                    throw Error.invalidUTF8(scalar: scalar)
                }
            }
        case .utf16BigEndian, .utf16, .unicode: // UTF16 & Unicode imply: follow the BOM and if it is not there, assume big endian.
            return { [unowned stream] (scalar) in
                guard let tmp = Unicode.UTF16.encode(scalar) else { throw Error.invalidUTF16(scalar: scalar) }
                let bytes = tmp.flatMap {
                    [UInt8(truncatingIfNeeded: $0 >> 8),
                     UInt8(truncatingIfNeeded: $0)]
                }
                try CSVWriter.lowlevelWriter(on: stream, bytes: bytes, count: bytes.count)
            }
        case .utf16LittleEndian:
            return { [unowned stream] (scalar) in
                guard let tmp = Unicode.UTF16.encode(scalar) else { throw Error.invalidUTF16(scalar: scalar) }
                let bytes = tmp.flatMap {
                    [UInt8(truncatingIfNeeded: $0),
                     UInt8(truncatingIfNeeded: $0 >> 8)]
                }
                try CSVWriter.lowlevelWriter(on: stream, bytes: bytes, count: bytes.count)
            }
        case .utf32BigEndian, .utf32:
            return { [unowned stream] (scalar) in
                guard let tmp = Unicode.UTF32.encode(scalar) else { throw Error.invalidUTF32(scalar: scalar) }
                let bytes = tmp.flatMap {
                    [UInt8(truncatingIfNeeded: $0 >> 24),
                     UInt8(truncatingIfNeeded: $0 >> 16),
                     UInt8(truncatingIfNeeded: $0 >> 8),
                     UInt8(truncatingIfNeeded: $0)]
                }
                try CSVWriter.lowlevelWriter(on: stream, bytes: bytes, count: bytes.count)
            }
        case .utf32LittleEndian:
            return { [unowned stream] (scalar) in
                guard let tmp = Unicode.UTF32.encode(scalar) else { throw Error.invalidUTF32(scalar: scalar) }
                let bytes = tmp.flatMap {
                    [UInt8(truncatingIfNeeded: $0),
                     UInt8(truncatingIfNeeded: $0 >> 8),
                     UInt8(truncatingIfNeeded: $0 >> 16),
                     UInt8(truncatingIfNeeded: $0 >> 24)]
                }
                try CSVWriter.lowlevelWriter(on: stream, bytes: bytes, count: bytes.count)
            }
        default: throw Error.unsupported(encoding: encoding)
        }
    }
}

fileprivate extension CSVWriter {
    /// Writes on the stream the given bytes.
    static func lowlevelWriter(on stream: OutputStream, bytes: UnsafePointer<UInt8>, count: Int, attempts: Int = 2) throws {
        var (distance, remainingAttempts) = (0, attempts)
        
        repeat {
            let written = stream.write(bytes.advanced(by: distance), maxLength: count - distance)
            
            if written > 0 {
                distance += written
            } else if written == 0 {
                remainingAttempts -= 1
                guard remainingAttempts > 0 else {
                    throw Error.streamEmptyWrite(underlyingError: stream.streamError, status: stream.streamStatus, numAttempts: attempts)
                }
            } else {
                throw Error.streamFailed(underlyingError: stream.streamError, status: stream.streamStatus)
            }
        } while distance < count
    }
}

fileprivate extension CSVWriter.Error {
    /// The given `String.Encoding` is not yet supported by the library.
    /// - parameter encoding: The desired byte representatoion.
    static func unsupported(encoding: String.Encoding) -> CSVError<CSVWriter> {
        .init(.invalidConfiguration,
              reason: "The given encoding is not yet supported by this library",
              help: "Contact the library maintainer",
              userInfo: ["Encoding": encoding])
    }
    /// Error raised when a Unicode scalar is an invalid ASCII character.
    /// - parameter byte: The byte being decoded from the input data.
    static func invalidASCII(scalar: Unicode.Scalar) -> CSVError<CSVReader> {
        .init(.invalidInput,
              reason: "The Unicode Scalar is not an ASCII character.",
              help: "Make sure the CSV only contains ASCII characters or select a different encoding (e.g. UTF8).",
              userInfo: ["Unicode scalar": scalar])
    }
    /// Error raised when a UTF8 character cannot be constructed from a Unicode scalar value.
    static func invalidUTF8(scalar: Unicode.Scalar) -> CSVError<CSVReader> {
        .init(.invalidInput,
              reason: "The Unicode Scalar couldn't be decoded as UTF8 characters",
              help: "Make sure the CSV only contains UTF8 characters or select a different encoding.",
              userInfo: ["Unicode scalar": scalar])
    }
    /// Error raised when a UTF16 character cannot be constructed from a Unicode scalar value.
    static func invalidUTF16(scalar: Unicode.Scalar) -> CSVError<CSVReader> {
        .init(.invalidInput,
              reason: "The Unicode Scalar couldn't be decoded as multibyte UTF16",
              help: "Make sure the CSV only contains UTF16 characters.",
              userInfo: ["Unicode scalar": scalar])
    }
    /// Error raised when a UTF32 character cannot be constructed from a Unicode scalar value.
    static func invalidUTF32(scalar: Unicode.Scalar) -> CSVError<CSVReader> {
        .init(.invalidInput,
              reason: "The Unicode Scalar couldn't be decoded as multibyte UTF32",
              help: "Make sure the CSV only contains UTF32 characters.",
              userInfo: ["Unicode scalar": scalar])
    }
    ///
    static func streamFailed(underlyingError: Swift.Error?, status: Stream.Status) -> CSVError<CSVWriter> {
        .init(.streamFailure, underlying: underlyingError,
              reason: "The output stream encountered an error while trying to write encoded bytes",
              help: "Review the underlying error and make sure you have access to the output data (if it is a file)",
              userInfo: ["Status": status])
    }
    ///
    static func streamEmptyWrite(underlyingError: Swift.Error?, status: Stream.Status, numAttempts: Int) -> CSVError<CSVWriter> {
        .init(.streamFailure, underlying: underlyingError,
              reason: "Several attempts were made to write on the stream, but they were unsuccessful.",
              help: "Review the underlying error (if any) and try again.",
              userInfo: ["Status": status, "Attempts": numAttempts])
    }
}
