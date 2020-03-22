import Foundation

internal extension CSVWriter {
    /// Select the writer output encoding given the user provided string encoding and the inferred string encoding from a pre-existing file (if any).
    static func selectEncodingFrom(provided: String.Encoding?, inferred: String.Encoding?) throws -> String.Encoding {
        switch (provided, inferred) {
        case (let e?, nil): return e
        case (nil, let e?): return e
        case (nil, nil): return .utf8
        case (let lhs?, let rhs?) where lhs == rhs: return lhs
        case (let lhs?, let rhs?): throw CSVWriter.Error.invalidEncoding(provided: lhs, file: rhs)
        }
    }
}

internal extension Strategy.BOM {
    /// The Byte Order Marker bytes.
    /// - parameter encoding: The result bytes will represent this encoding.
    func bytes(encoding: String.Encoding) -> [UInt8] {
        switch (self, encoding) {
        case (.always, .utf8): return BOM.UTF8
        case (.always, .utf16LittleEndian): return BOM.UTF16.littleEndian
        case (.always, .utf16BigEndian),
             (.always, .utf16),   (.standard, .utf16),
             (.always, .unicode), (.standard, .unicode): return BOM.UTF16.bigEndian
        case (.always, .utf32LittleEndian): return BOM.UTF32.littleEndian
        case (.always, .utf32BigEndian),
             (.always, .utf32),   (.standard, .utf32): return BOM.UTF32.bigEndian
        default: return .init()
        }
    }
}

// MARK: - Delimiter Detector Factory

internal extension CSVWriter {
    /// Closure returning a Boolean indicating whether the given input at the given index (and subsquent unicode scalars) form a delimiter.
    ///
    /// If the marked input is a delimiter, the index is modified and the delimiter is appended.
    typealias DelimiterChecker = (_ input: [Unicode.Scalar], _ index: inout Int, _ result: inout [Unicode.Scalar]) -> Bool
    
    /// Creates a delimiter identifier closure.
    static func makeMatcher(delimiter: [Unicode.Scalar]) -> DelimiterChecker  {
        // This should never be triggered.
        precondition(!delimiter.isEmpty, "Delimiters must include at least one unicode scalar.")
        
        // For optimization sake, a delimiter proofer is built for a unique single unicode scalar.
        if delimiter.count == 1 {
            let scalar = delimiter.first!
            return { (input, index, result) in
                let isDelimiter = input[index] == scalar
                
                if isDelimiter {
                    index += 1
                    result.append(scalar)
                }
                
                return isDelimiter
            }
        } else {
            return { [count = delimiter.count] (input, index, result) in
                let remainingScalars = input.endIndex - index
                guard remainingScalars >= count else { return false }
                
                for i in 0..<count where delimiter[i] != input[index+i] { return false }
                
                index += count
                result.append(contentsOf: delimiter)
                return true
            }
        }
    }
}

// MARK: -

fileprivate extension CSVWriter.Error {
    /// Error raised when the provided string encoding is different than the inferred file encoding.
    /// - parameter provided: The string encoding provided by the user.
    /// - parameter file: The string encoding in the targeted file.
    static func invalidEncoding(provided: String.Encoding, file: String.Encoding) -> CSVError<CSVWriter> {
        .init(.invalidConfiguration,
              reason: "The encoding provided was different than the encoding detected on the file.",
              help: "Set the configuration encoding to nil or to the file encoding.",
              userInfo: ["Provided encoding": provided, "File encoding": file])
    }
}
