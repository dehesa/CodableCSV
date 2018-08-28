import Foundation

extension CSVWriter {
    /// Errors that can be thrown from a CSV writer instance.
    public enum Error: Swift.Error, CustomDebugStringConvertible {
        /// The defined delimiter (whether field or row) was invalid. Please check the configuration.
        case invalidDelimiter(message: String)
        /// The output stream failed is some way. Please check the message for more information.
        case outputStreamFailed(message: String)
        /// The command given to the writer cannot be processed.
        case invalidCommand(message: String)
        /// The input couldn't be recognized or was `nil`.
        case invalidInput(message: String)
        
        public var debugDescription: String {
            var result = "[CSVWriter] "
            switch self {
            case .invalidDelimiter(let message):
                result.append("Invalid delimiter: ")
                result.append(message)
            case .outputStreamFailed(let message):
                result.append("Output stream failed: ")
                result.append(message)
            case .invalidCommand(let message):
                result.append("Invalid command: ")
                result.append(message)
            case .invalidInput(let message):
                result.append("Invalid input: ")
                result.append(message)
            }
            return result
        }
    }
}
