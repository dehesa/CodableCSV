import Foundation

extension EncodingError.Context {
    /// Context for invalid coding keys.
    /// - parameter key: The key that giving the problem.
    /// - parameter codingPath: The full chain of containers when this error context was generated.
    internal static func invalidKey(_ key: CodingKey, codingPath: [CodingKey]) -> EncodingError.Context {
        return .init(codingPath: codingPath, debugDescription: "The key requested is invalid; either because it cannot be transformed to an `Int` or it is out of bounds.")
    }
    
    /// Context for errors when a row is not at the expected position.
    /// - parameter codingPath: The full chain of containers when this error context was generated.
    internal static func invalidRow(codingPath: [CodingKey]) -> EncodingError.Context {
        return .init(codingPath: codingPath, debugDescription: "The CSV row that this encoding container pointed to has been already fully encoded or it is invalid.")
    }
    
    /// Context for errors when the row is not single column.
    /// - parameter codingPath: The full chain of containers when this error context was generated.
    internal static func isNotSingleColumn(codingPath: [CodingKey]) -> EncodingError.Context {
        return .init(codingPath: codingPath, debugDescription: "The CSV has more than one column. The requested function only works for single column CSV files.")
    }
    
    /// Context for internal errors occurred when low-level writing.
    /// - parameter field: The raw field value that was going to be writen.
    /// - parameter codingPath: The full chain of containers when this error context was generated.
    /// - parameter error: The underlying error that has generated the returning error.
    internal static func writingFailed(field: String, codingPath: [CodingKey], underlyingError error: Swift.Error?)
        -> EncodingError.Context {
        return .init(codingPath: codingPath, debugDescription: "The field \(field) couldn't be writen due to a low-level CSV writer error.", underlyingError: error)
    }
}
