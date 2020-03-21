extension CSVWriter {
    /// Closure accepting a scalar and returning a Boolean indicating whether the scalar (and subsquent unicode scalars) form a delimiter.
    private typealias DelimiterChecker = (_ scalar: Unicode.Scalar, _ iterator: inout String.UnicodeScalarView.Iterator) -> Bool
    
    /// Creates a delimiter identifier closure.
    private static func matchCreator(delimiter view: String.UnicodeScalarView, buffer: ScalarBuffer) -> DelimiterChecker  {
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
