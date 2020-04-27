internal extension CSVWriter {
    /// Closure returning a Boolean indicating whether the given input at the given index form a delimiter.
    ///
    /// If the given input is a delimiter, the `index` is modified and the delimiter is appended to `result`.
    /// - parameter input: The input containing all unicode scalars in a CSV field.
    /// - parameter index: The index from which the `input` is analyzed.
    /// - parameter result: The unicode scalars to write as output.
    /// - returns: Boolean indicating whether the input at the given index contained a delimiter.
    typealias DelimiterChecker = (_ input: [Unicode.Scalar], _ index: inout Int, _ result: inout [Unicode.Scalar]) -> Bool
    
    /// Creates a delimiter identifier closure.
    /// - parameter delimiter: Unicode scalars forming the field or row delimiters. The delimiter can have one or multiple unicode scalars.
    /// - returns: A function checking for `delimiter` on a given input and index.
    static func makeMatcher(delimiter: [Unicode.Scalar]) -> DelimiterChecker  {
        // This should never be triggered.
        precondition(!delimiter.isEmpty, "Delimiters must include at least one unicode scalar.")
        
        // For optimization sake, a _delimiter checker_ is built for a unique single unicode scalar.
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
        // For delimiters of two or more unicode scalars.
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
