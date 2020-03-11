extension CSVWriter {
    /// Errors that can be thrown from a CSV writer instance.
    public enum Error: Swift.Error, CustomDebugStringConvertible {
        /// The defined delimiter (whether field or row) was invalid. Please check the configuration.
        case invalidDelimiter(String)
        /// The pass String encoding is not supported at the moment.
        case unsupportedEncoding(String.Encoding)
        /// The output stream failed is some way. Please check the message for more information.
        case outputStreamFailed(String, underlyingError: Swift.Error?)
        /// The command given to the writer cannot be processed.
        case invalidCommand(String)
        /// The input couldn't be recognized or was `nil`.
        case invalidInput(String)
        
        public var debugDescription: String {
            var result = "[CSVWriter] "
            switch self {
            case .invalidDelimiter(let message):
                result.append("Invalid delimiter: ")
                result.append(message)
            case .unsupportedEncoding(let encoding):
                result.append("Unsupported encoding: ")
                result.append("The String encoding '\(encoding)' is not currently supported.")
            case .outputStreamFailed(let message, let underlyingError):
                result.append("Output stream failed: ")
                result.append(message)
                if let error = underlyingError {
                    result.append("\nUnderlying Error: \(error)")
                }
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
