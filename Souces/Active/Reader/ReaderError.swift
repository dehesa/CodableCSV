import Foundation

extension CSVReader {
    /// Errors that can be thrown from a CSV reader instance.
    public enum Error: Swift.Error, CustomDebugStringConvertible {
        /// The input couldn't be recognized or was `nil`.
        case invalidInput(message: String)
        /// The defined delimiter (whether field or row) was invalid. Please check the configuration.
        case invalidDelimiter(message: String)
        /// The inferral process to figure out delimiters or header row status was unsuccessful.
        case unsuccessfulInferral(message: String)
        
        public var debugDescription: String {
            var result = "[CSVReader] "
            switch self {
            case .invalidInput(let message):
                result.append("Invalid input: ")
                result.append(message)
            case .invalidDelimiter(let message):
                result.append("Invalid delimiter: ")
                result.append(message)
            case .unsuccessfulInferral(let message):
                result.append("Inferral unsuccessful: ")
                result.append(message)
            }
            return result
        }
    }
}
