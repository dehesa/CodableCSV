import Foundation

extension CSVReader {
    /// Errors that can be thrown from a CSV reader instance.
    public final class Error: LocalizedError, CustomNSError {
        /// The type of error being raised.
        public let type: Kind
        /// A localized message describing the reason for the failure.
        public let failureReason: String?
        /// A localized message describing how one might recover from the failure.
        public let recoverySuggestion: String?
        /// A localized message providing "help" text if the user requests help.
        public let helpAnchor: String?
        /// Any further context given needed information to debug the error.
        public let errorUserInfo: [String:Any]
        /// Any underlying error that cascade into this error.
        public let underlyingError: Swift.Error?
        
        /// Designated initializer.
        internal init(_ type: Kind, underlying: Swift.Error? = nil, reason: String, recovery: String? = nil, help: String? = nil, userInfo: [String:Any] = [:]) {
            self.type = type
            self.failureReason = reason
            self.recoverySuggestion = recovery
            self.helpAnchor = help
            self.errorUserInfo = userInfo
            self.underlyingError = underlying
        }
        
        /// A localized message describing what error occurred.
        public var errorDescription: String? {
            switch self.type {
            case .invalidConfiguration: return "Invalid configuration"
//            case .inferenceFailure: return "Inference failure"
            case .invalidInput: return "Invalid input"
            case .streamFailure: return "Stream failure"
            }
        }
        
        public static var errorDomain: String {
            "CodableCSV.CSVReader"
        }
        
        public var errorCode: Int {
            self.type.rawValue
        }
        
        public var localizedDescription: String {
            var result = "[CSVReader] \(self.errorDescription!)"
            if let reason = self.failureReason {
                result.append("\n\tReason: \(reason)")
            }
            if let recovery = self.recoverySuggestion {
                result.append("\n\tRecovery: \(recovery)")
            }
            if let help = self.helpAnchor {
                result.append("\n\tHelp: \(help)")
            }
            if !self.errorUserInfo.isEmpty {
                result.append("\n\tUser info: ")
                result.append(self.errorUserInfo.map { "\($0): \($1)" }.joined(separator: ", "))
            }
            if let error = self.underlyingError {
                result.append("\n\tUnderlying error: \(error)")
            }
            return result
        }
    }
}

extension CSVReader.Error {
    /// The type of error raised by the reader.
    public enum Kind: Int {
        /// Some of the configuration values provided are invalid.
        case invalidConfiguration = 1
        /// The CSV data is invalid.
        case invalidInput = 2
//        /// The inferral process to figure out delimiters or header row status was unsuccessful.
//        case inferenceFailure = 3
        /// The input stream failed.
        case streamFailure = 4
    }
}
