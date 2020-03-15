import Foundation

extension CSVReader {
    /// Errors that can be thrown from a CSV reader instance.
    public struct Error: LocalizedError, CustomNSError {
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
            case .invalidDelimiter: return "Invalid delimiter"
            case .inferenceFailure: return "Inference failure"
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
        /// The input couldn't be recognized or was `nil`.
        case invalidInput = 1
        /// The defined delimiter (whether field or row) was invalid. Please check the configuration.
        case invalidDelimiter = 2
        /// The inferral process to figure out delimiters or header row status was unsuccessful.
        case inferenceFailure = 8
        /// The data stream failed.
        case streamFailure = 16
    }
}

extension CSVReader.Error {
    /// Error when the parsed byte is invalid.
    internal static func invalidASCII(byte: UInt8) -> CSVReader.Error {
        .init(.invalidInput,
              reason: "The decoded byte is not an ASCII character.",
              help: "Make sure the CSV only contains ASCII characters or mark the encoding as UTF8.",
              userInfo: ["Byte": byte])
    }
    /// Error produced when a UTF8 character cannot be built.
    internal static func invalidUTF8() -> CSVReader.Error {
        .init(.invalidInput,
              reason: "Some input bytes couldn't be decoded as UTF8 characters",
              help: "Make sure the CSV only contains UTF8 characters.")
    }
    /// Error produced when a UTF16 character cannot be built.
    internal static func invalidMultibyteUTF() -> CSVReader.Error {
        .init(.invalidInput,
              reason: "Some input bytes couldn't be decoded as multibyte UTF characters",
              help: "Make sure the CSV only contains UTF characters.")
    }
}
