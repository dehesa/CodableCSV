import Foundation

extension CSVReader {
    /// Errors that can be thrown from the CSV reader.
    public enum Error: Swift.Error {
        /// The input couldn't be recognized or was `nil`.
        case invalidInput(message: String)
        /// The defined delimiter (whether field or row) was invalid. Please check the configuration.
        case invalidDelimiter(message: String)
        /// The inferral process to figure out delimiters or header row status was unsuccessful.
        case unsuccessfulInferral(message: String)
    }
}
