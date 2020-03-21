internal extension CSVReader {
    /// Tries to infer the field delimiter given the row delimiter.
    /// - throws: `CSVError<CSVReader>` exclusively.
    static func inferFieldDelimiter(rowDelimiter: String.UnicodeScalarView, iterator: ScalarIterator, buffer: ScalarBuffer) throws -> Delimiter.RawPair {
        throw Error.unsupportedInference()
    }
    
    /// Tries to infer the row delimiter given the field delimiter.
    /// - throws: `CSVError<CSVReader>` exclusively.
    static func inferRowDelimiter(fieldDelimiter: String.UnicodeScalarView, iterator: ScalarIterator, buffer: ScalarBuffer) throws -> Delimiter.RawPair {
        throw Error.unsupportedInference()
    }
    
    /// Tries to infer both the field and row delimiter from the raw data.
    /// - throws: `CSVError<CSVReader>` exclusively.
    static func inferDelimiters(iterator: ScalarIterator, buffer: ScalarBuffer) throws -> Delimiter.RawPair {
        throw Error.unsupportedInference()
    }
}

// MARK: - Delimiter Dectector Factory

internal extension CSVReader {
    /// Closure accepting a scalar and returning a Boolean indicating whether the scalar (and subsquent unicode scalars) form a delimiter.
    /// - parameter scalar: The scalar that may start a delimiter.
    /// - throws: `CSVError<CSVReader>` exclusively.
    typealias DelimiterChecker = (_ scalar: Unicode.Scalar) throws -> Bool
    
    /// Creates a delimiter identifier closure.
    /// - parameter view: The unicode characters forming a targeted delimiter.
    /// - parameter buffer: A unicode character buffer containing further characters to parse.
    /// - parameter iterator: A unicode character buffer containing further characters to parse.
    /// - returns: A closure which given the targeted unicode character and the buffer and iterrator, returns a Boolean indicating whether there is a delimiter.
    static func makeMatcher(delimiter view: String.UnicodeScalarView, buffer: ScalarBuffer, iterator: CSVReader.ScalarIterator) -> CSVReader.DelimiterChecker {
        // This should never be triggered.
        assert(!view.isEmpty)
        
        // For optimizations sake, a delimiter proofer is built for a single unicode scalar.
        if view.count == 1 {
            let delimiter: Unicode.Scalar = view.first!
            return { delimiter == $0 }
            // For optimizations sake, a delimiter proofer is built for two unicode scalars.
        } else if view.count == 2 {
            let firstDelimiter = view.first!
            let secondDelimiter = view[view.index(after: view.startIndex)]
            
            return { [unowned buffer, unowned iterator] in
                guard firstDelimiter == $0, let secondScalar = try buffer.next() ?? iterator.next() else {
                    return false
                }
                
                let result = secondDelimiter == secondScalar
                if !result {
                    buffer.preppend(scalar: secondScalar)
                }
                return result
            }
            // For completion sake, a delimiter proofer is build for +2 unicode scalars.
            // CSV files with multiscalar delimiters are very very rare.
        } else {
            return { [unowned buffer, unowned iterator] (firstScalar) -> Bool in
                var scalar = firstScalar
                var index = view.startIndex
                var toIncludeInBuffer: [Unicode.Scalar] = .init()
                
                while true {
                    guard scalar == view[index] else {
                        buffer.preppend(scalars: toIncludeInBuffer)
                        return false
                    }
                    
                    index = view.index(after: index)
                    guard index < view.endIndex else { return true }
                    
                    guard let nextScalar = try buffer.next() ?? iterator.next() else {
                        buffer.preppend(scalars: toIncludeInBuffer)
                        return false
                    }
                    
                    toIncludeInBuffer.append(nextScalar)
                    scalar = nextScalar
                }
            }
        }
    }
}

fileprivate extension CSVReader.Error {
    /// Delimiter inference is not yet implemented.
    static func unsupportedInference() -> CSVError<CSVReader> {
        .init(.invalidConfiguration,
              reason: "Delimiter inference is not yet supported by this library",
              help: "Specify a concrete delimiter or get in contact with the maintainer")
    }
}
