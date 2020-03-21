import Foundation

internal extension String.Encoding {
    /// Select the writer output encoding given the user provided string encoding and the inferred string encoding from a pre-existing file (if any).
    static func selectFrom(provided: String.Encoding?, inferred: String.Encoding?, serializeBOM: CSVWriter.BOMSerialization) throws -> (encoding: String.Encoding, bom: [UInt8]) {
        let result: (encoding :String.Encoding, bom: [UInt8])
        
        switch (provided, inferred) {
        case (let e?, nil): result.encoding = e
        case (nil, let e?): result.encoding = e
        case (nil, nil): result.encoding = .utf8
        case (let lhs?, let rhs?) where lhs == rhs: result.encoding = lhs
        case (let lhs?, let rhs?): throw CSVWriter.Error.invalidEncoding(provided: lhs, file: rhs)
        }
        
        switch (serializeBOM, result.encoding) {
        case (.always, .utf8): result.bom = BOM.UTF8
        case (.always, .utf16LittleEndian): result.bom = BOM.UTF16.littleEndian
        case (.always, .utf16BigEndian),
             (.always, .utf16),   (.standard, .utf16),
             (.always, .unicode), (.standard, .unicode): result.bom = BOM.UTF16.bigEndian
        case (.always, .utf32LittleEndian): result.bom = BOM.UTF32.littleEndian
        case (.always, .utf32BigEndian),
             (.always, .utf32),   (.standard, .utf32): result.bom = BOM.UTF32.bigEndian
        default: result.bom = .init()
        }
        
        return result
    }
}

// MARK: - Delimiter Detector Factory

internal extension CSVWriter {
    /// Closure accepting a scalar and returning a Boolean indicating whether the scalar (and subsquent unicode scalars) form a delimiter.
    typealias DelimiterChecker = (_ scalar: Unicode.Scalar, _ iterator: inout String.UnicodeScalarView.Iterator) -> Bool
    
    /// Creates a delimiter identifier closure.
    static func matchCreator(delimiter view: String.UnicodeScalarView, buffer: ScalarBuffer) -> DelimiterChecker  {
        // This should never be triggered.
        precondition(!view.isEmpty, "Delimiters must include at least one unicode scalar.")
        
        // For optimization sake, a delimiter proofer is built for a unique single unicode scalar.
        if view.count == 1 {
            let delimiter = view.first!
            return { (scalar, _) in delimiter == scalar }
        // For optimizations sake, a delimiter proofer is built for two unicode scalars.
        } else if view.count == 2 {
            let firstDelimiter = view.first!
            let secondDelimiter = view[view.index(after: view.startIndex)]
            
            return { [unowned buffer] (firstScalar, iterator) in
                guard firstDelimiter == firstScalar, let secondScalar = buffer.next() ?? iterator.next() else {
                    return false
                }
                
                buffer.preppend(scalar: secondScalar)
                return secondDelimiter == secondScalar
            }
        // For completion sake, a delimiter proofer is build for +2 unicode scalars.
        // CSV files with multiscalar delimiters are very very rare (if non-existant).
        } else {
            return { [unowned buffer] (firstScalar, iterator) in
                var scalar = firstScalar
                var index = view.startIndex
                var toIncludeInBuffer: [Unicode.Scalar] = .init()
                defer {
                    if !toIncludeInBuffer.isEmpty {
                        buffer.preppend(scalars: toIncludeInBuffer)
                    }
                }
                
                while true {
                    guard scalar == view[index] else { return false }
                    
                    index = view.index(after: index)
                    guard index < view.endIndex else { return true }
                    
                    guard let nextScalar = buffer.next() ?? iterator.next() else { return false }
                    
                    toIncludeInBuffer.append(nextScalar)
                    scalar = nextScalar
                }
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
