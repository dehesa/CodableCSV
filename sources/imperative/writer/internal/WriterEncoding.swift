internal extension CSVWriter {
    /// Select the writer output encoding given the user provided string encoding and the inferred string encoding from a pre-existing file (if any).
    /// - parameter provided: The string encoding provided by the user in the configuration values.
    /// - parameter inferred: The string encoding inferred from a pre-existing file (if any).
    /// - throws: `CSVError<CSVWriter>` exclusively.
    /// - returns: The string encoding satisfying both criteria.
    static func selectEncodingFrom(provided: String.Encoding?, inferred: String.Encoding?) throws -> String.Encoding {
        switch (provided, inferred) {
        case (let e?, nil): return e
        case (nil, let e?): return e
        case (nil, nil): return .utf8
        case (let lhs?, let rhs?) where lhs == rhs: return lhs
        case (let lhs?, let rhs?): throw Error._invalidEncoding(provided: lhs, file: rhs)
        }
    }
}

internal extension Strategy.BOM {
    /// The Byte Order Marker bytes for the given encoding and the receiving BOM strategy.
    /// - parameter encoding: The string encoding that will be represented by the returned bytes.
    /// - returns: Array of bytes representing the given string encoding.
    func bytes(encoding: String.Encoding) -> [UInt8] {
        switch (self, encoding) {
        case (.always, .utf8): return BOM.UTF8
        case (.always, .utf16LittleEndian): return BOM.UTF16.littleEndian
        case (.always, .utf16BigEndian),
             (.always, .utf16),   (.convention, .utf16),
             (.always, .unicode), (.convention, .unicode): return BOM.UTF16.bigEndian
        case (.always, .utf32LittleEndian): return BOM.UTF32.littleEndian
        case (.always, .utf32BigEndian),
             (.always, .utf32),   (.convention, .utf32): return BOM.UTF32.bigEndian
        default: return Array()
        }
    }
}

// MARK: -

fileprivate extension CSVWriter.Error {
    /// Error raised when the provided string encoding is different than the inferred file encoding.
    /// - parameter provided: The string encoding provided by the user.
    /// - parameter file: The string encoding in the targeted file.
    static func _invalidEncoding(provided: String.Encoding, file: String.Encoding) -> CSVError<CSVWriter> {
        .init(.invalidConfiguration,
              reason: "The encoding provided was different than the encoding detected on the file.",
              help: "Set the configuration encoding to nil or to the file encoding.",
              userInfo: ["Provided encoding": provided, "File encoding": file])
    }
}
