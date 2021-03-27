internal extension Delimiter.Scalars {
    /// Closure accepting a scalar and returning a Boolean indicating whether the scalar (and subsquent unicode scalars from the input) form a delimiter.
    /// - parameter scalar: The scalar that may start a delimiter.
    /// - throws: `CSVError<CSVReader>` exclusively.
    typealias Checker = (_ scalar: Unicode.Scalar) throws -> Bool
    
    /// Creates a field delimiter identifier closure.
    /// - parameter buffer: A unicode character buffer containing further characters to parse.
    /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
    /// - returns: A closure which given the targeted unicode character and the buffer and iterrator, returns a Boolean indicating whether there is a field delimiter.
    func makeFieldMatcher(buffer: CSVReader.ScalarBuffer, decoder: @escaping CSVReader.ScalarDecoder) -> Self.Checker {
        Self._makeMatcher(delimiter: self.field, buffer: buffer, decoder: decoder)
    }
    
    /// Creates a row delimiter identifir closure.
    /// - parameter buffer: A unicode character buffer containing further characters to parse.
    /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
    /// - returns: A closure which given the targeted unicode character and the buffer and iterrator, returns a Boolean indicating whether there is a row delimiter.
    func makeRowMatcher(buffer: CSVReader.ScalarBuffer, decoder: @escaping CSVReader.ScalarDecoder) -> Self.Checker {
        guard self.row.count > 1 else {
            return Self._makeMatcher(delimiter: self.row.first!, buffer: buffer, decoder: decoder)
        }
        
        let delimiters = self.row.sorted { $0.count < $1.count }
        let maxScalars = delimiters.last!.count
        
        // For optimization sake, a delimiter proofer is built for s single value scalar.
        if maxScalars == 1 {
            return { [dels = delimiters.map { $0.first! }] in dels.contains($0) }
        // For optimization sake, a delimiter proofer is built for two unicode scalars.
        } else if maxScalars == 2 {
            return { [storage = Unmanaged.passUnretained(buffer), decoder,
                      singles = delimiters.compactMap { ($0.count == 1) ? $0.first! : nil },
                      doubles = delimiters.compactMap { ($0.count == 2) ? ($0[0], $0[1]) : nil }] (firstScalar) in
                if singles.contains(firstScalar) { return true }
                return try storage._withUnsafeGuaranteedRef {
                    guard let secondScalar = try $0.next() ?? decoder() else { return false }
                    for (first, second) in doubles where first==firstScalar && second==secondScalar { return true }
                    $0.preppend(scalar: secondScalar)
                    return false
                }
            }
        } else {
            return { [storage = Unmanaged.passUnretained(buffer), decoder] (scalar) in
                #warning("Finish edge-case implementation")
                fatalError()
            }
        }
    }
}

private extension Delimiter.Scalars {
    /// Creates a delimiter identifier closure.
    /// - parameter delimiter: The value to be checked for.
    /// - parameter buffer: A unicode character buffer containing further characters to parse.
    /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
    static func _makeMatcher(delimiter: [Unicode.Scalar], buffer: CSVReader.ScalarBuffer, decoder: @escaping CSVReader.ScalarDecoder) -> Self.Checker {
        // For optimizations sake, a delimiter proofer is built for a single unicode scalar.
        if delimiter.count == 1 {
            return { [s = delimiter[0]] in $0 == s }
        // For optimizations sake, a delimiter proofer is built for two unicode scalars.
        } else if delimiter.count == 2 {
            return { [storage = Unmanaged.passUnretained(buffer), decoder, first = delimiter[0], second = delimiter[1]] in
                guard $0 == first else { return false }
                return try storage._withUnsafeGuaranteedRef {
                    guard let nextScalar = try $0.next() ?? decoder() else { return false }
                    if second == nextScalar { return true }
                    else { $0.preppend(scalar: nextScalar); return false }
                }
            }
        // For completion sake, a delimiter proofer is build for +2 unicode scalars. CSV files with multiscalar delimiters are very very rare.
        } else {
            return { [storage = Unmanaged.passUnretained(buffer), decoder] (firstScalar) -> Bool in
                try storage._withUnsafeGuaranteedRef {
                    var scalar = firstScalar
                    var index = delimiter.startIndex
                    var toIncludeInBuffer: [Unicode.Scalar] = Array()
                    
                    while true {
                        guard scalar == delimiter[index] else {
                            $0.preppend(scalars: toIncludeInBuffer)
                            return false
                        }
                        
                        index = delimiter.index(after: index)
                        guard index < delimiter.endIndex else { return true }
                        
                        guard let nextScalar = try $0.next() ?? decoder() else {
                            $0.preppend(scalars: toIncludeInBuffer)
                            return false
                        }
                        
                        toIncludeInBuffer.append(nextScalar)
                        scalar = nextScalar
                    }
                }
            }
        }
    }
}

internal extension CSVReader {
    /// Tries to infer both the field and row delimiter from the raw data.
    /// - parameter field: The field delimiter specified by the user.
    /// - parameter row: The row delimiter specified by the user.
    /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
    /// - parameter buffer: Small buffer use to store `Unicode.Scalar` values that have been read from the input, but haven't yet been processed.
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - todo: Implement the field and row inferences.
    static func inferDelimiters(field: Delimiter.Field, row: Delimiter.Row, decoder: ScalarDecoder, buffer: ScalarBuffer) throws -> Delimiter.Scalars {
        switch (field.isKnown, row.isKnown) {
        case (true, true):
            guard let delimiters = Delimiter.Scalars(field: field.scalars, row: row.scalars) else {
                throw Error._invalidDelimiters(field: field, row: row)
            }
            return delimiters
        default: throw Error._unsupportedInference()
        }
    }
}

fileprivate extension CSVReader.Error {
    /// Error raised when the field and row delimiters are the same.
    /// - parameter delimiter: The indicated field and row delimiters.
    static func _invalidDelimiters(field: Delimiter.Field, row: Delimiter.Row) -> CSVError<CSVReader> {
        .init(.invalidConfiguration,
              reason: "The field and row delimiters cannot be the same.",
              help: "Set different delimiters for fields and rows.",
              userInfo: ["Field delimiter": field.scalars, "Row delimiters": row.scalars])
    }
    /// Delimiter inference is not yet implemented.
    static func _unsupportedInference() -> CSVError<CSVReader> {
        .init(.invalidConfiguration,
              reason: "Delimiter inference is not yet supported by this library",
              help: "Specify a concrete delimiter or get in contact with the maintainer")
    }
}
