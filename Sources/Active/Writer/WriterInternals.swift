extension CSVWriter {
    /// The type of error raised by the CSV writer.
    public enum Error: Int {
        /// Some of the configuration values provided are invalid.
        case invalidConfiguration = 1
        /// The CSV data is invalid.
        case invalidInput = 2
        /// The output stream failed.
        case streamFailure = 4
        /// The operation couldn't be carried or failed midway.
        case invalidOperation = 5
    }
}

extension CSVWriter: Failable {
    public static var errorDomain: String { "Writer" }
    
    public static func errorDescription(for failure: Error) -> String {
        switch failure {
        case .invalidConfiguration: return "Invalid configuration"
        case .invalidInput: return "Invalid Input"
        case .streamFailure: return "Stream failure"
        case .invalidOperation: return "Invalid Operation"
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
    /// - parameter delimiter: Unicode scalars forming the field or row delimiters.
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
