import Foundation

/// Errors that can be thrown from a CSV reader instance.
public final class CSVError<F>: LocalizedError, CustomNSError, CustomDebugStringConvertible where F:Failable {
    /// The type of error being raised.
    public let type: F.Failure
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
    internal init(_ type: F.Failure, underlying: Swift.Error? = nil, reason: String, recovery: String? = nil, help: String? = nil, userInfo: [String:Any] = [:]) {
        self.type = type
        self.failureReason = reason
        self.recoverySuggestion = recovery
        self.helpAnchor = help
        self.errorUserInfo = userInfo
        self.underlyingError = underlying
    }
    
    public static var errorDomain: String {
        "CodableCSV.\(F.errorDomain)"
    }
    
    public var errorCode: Int {
        self.type.rawValue
    }
    
    public var errorDescription: String? {
        F.errorDescription(for: self.type)
    }
    
    public var localizedDescription: String {
        var result = "[\(F.self)] \(self.errorDescription!)"
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
    
    public var debugDescription: String {
        return self.localizedDescription
    }
}

/// An instance that throws custom errors.
public protocol Failable: AnyObject {
    /// The type of error being thrown.
    associatedtype Failure: RawRepresentable where Failure.RawValue==Int
    /// The domain of the error being thrown.
    static var errorDomain: String { get }
    /// A description for an error being thrown that depends on the type of the error.
    static func errorDescription(for failure: Failure) -> String
}
