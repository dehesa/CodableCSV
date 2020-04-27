import Foundation

internal extension CSVReader {
    /// Select the appropriate encoding depending on the `String` encoding provided by the user and the encoding inferred from the Byte Order Marker.
    /// - parameter provided: The user provided `String` encoding.
    /// - parameter inferred: The `String` encoding inferred from the data Byte Order Marker.
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: The appropriate `String.Encoding` matching from the provided and inferred values.
    static func selectEncodingFrom(provided: String.Encoding?, inferred: String.Encoding?) throws -> String.Encoding {
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
            default: throw CSVReader.Error._mismatchedEncoding(provided: lhs, inferred: rhs)
            }
        }
    }
}

internal extension String.Encoding {
    /// Starts parsing the CSV file to try to figure out its encoding.
    ///
    /// This function looks for the Byte Order Mark (or [BOM](https://en.wikipedia.org/wiki/Byte_order_mark)) at the beginning of the file.
    /// - parameter iterator: The input data byte iterator.
    /// - returns: The inferred encoding (if any) and the bytes read from the input data (without the BOM bytes if any).
    static func infer<I>(from iterator: inout I) -> (encoding: String.Encoding?, unusedBytes: [UInt8]) where I:IteratorProtocol, I.Element==UInt8 {
        var unusedBytes: [UInt8]? = nil
        let encoding = self.init(unusedBytes: &unusedBytes, dataFetcher: {
            for i in 0..<$0.count {
                guard let byte = iterator.next() else { return i }
                $0[i] = byte
            }
            return $0.count
        })
        assert(unusedBytes != nil)
        return (encoding, unusedBytes!)
    }
    
    /// Starts parsing the CSV file to try to figure out its encoding.
    ///
    /// This function looks for the Byte Order Mark (or [BOM](https://en.wikipedia.org/wiki/Byte_order_mark)) at the beginning of the file.
    /// - parameter stream: The input stream reading the data's bytes.
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: The inferred encoding (if any) and the bytes read from the input data (without the BOM bytes if any).
    static func infer(from stream: InputStream) throws -> (encoding: String.Encoding?, unusedBytes: [UInt8]) {
        var unusedBytes: [UInt8]? = nil
        let encoding = try self.init(unusedBytes: &unusedBytes) { (buffer) -> Int in
            switch stream.read(buffer.baseAddress!, maxLength: buffer.count) {
            case -1: throw CSVReader.Error._streamReadFailure(error: stream.streamError, status: stream.streamStatus)
            case let count: return count
            }
        }
        assert(unusedBytes != nil)
        return (encoding, unusedBytes!)
    }
}

fileprivate extension String.Encoding {
    /// Creates a string encoding if the data return by `dataFetcher` contains BOM bytes.
    /// - parameter unusedBytes: The input data bytes that have been read, but are not part from the BOM.
    /// - parameter dataFetcher: Closure retrieving the input data up the the maximum supported by the given mutable buffer pointer. The closure returns the number of bytes actually read from the input data.
    /// - parameter buffer: The buffer where the input data bytes will be placed.
    private init?(unusedBytes: inout [UInt8]?, dataFetcher: (_ buffer: UnsafeMutableBufferPointer<UInt8>) throws -> Int) rethrows {
        // 1. Gather all BOMs and count what is the maximum number of bytes to represent any of them.
        let allEncodings = BOM.allCases
        let maxChars = allEncodings.reduce(0) { max($0, $1.value.count) }
        // 2. Retrieve the bytes from the input data.
        var bytes = try Array<UInt8>(unsafeUninitializedCapacity: maxChars) { $1 = try dataFetcher($0) }
        // 3. If the iterator did provide less than all required bytes, filter the encodings.
        let bytesCount = bytes.count
        let encodings = (bytesCount >= maxChars) ? allEncodings : allEncodings.filter { $0.value.count <= bytesCount }
        // 4. Select the encoding that matches the received bytes (if any).
        guard let result = encodings.first(where: { (encoding, bom) in bom.elementsEqual(bytes.prefix(bom.count)) }) else {
            unusedBytes = .some(bytes)
            return nil
        }
        bytes.removeFirst(result.value.count)
        unusedBytes = .some(bytes)
        self = result.key
    }
}

fileprivate extension CSVReader.Error {
    /// Error raised when an input stream cannot be created to the indicated file URL.
    /// - parameter error: Foundation's error causing this error.
    /// - parameter status: The input stream status when the error is received.
    static func _streamReadFailure(error: Swift.Error?, status: Stream.Status) -> CSVError<CSVReader> {
        .init(.streamFailure,
              underlying: error,
              reason: "The input stream encountered an error while trying to read the first bytes.",
              help: "Review the internal error and make sure you have access to the input data.",
              userInfo: ["Stream status": status])
    }
    /// Error raised when the input has a Byte Order Marker that is not matching the user provided encoding.
    /// - parameter provided: The user provided encoding.
    /// - parameter inferred: The encoding signalled by the BOM.
    static func _mismatchedEncoding(provided: String.Encoding, inferred: String.Encoding) -> CSVError<CSVReader> {
        .init(.invalidConfiguration,
              reason: "The encoding passed in the configuration doesn't match the Byte Order Mark (BOM) from the input data",
              help: "Set the appropriate encoding for the reader configuration or don't set any at all (pass nil)",
              userInfo: ["Provided encoding": provided, "Data BOM encoding": inferred])
    }
}
