import Foundation

extension EncodingError {
    /// Error thrown when a row is not at the expected position.
    /// - parameter value: Value trying to be encoded when the error happened.
    /// - parameter codingPath: The full chain of containers till `value`.
    internal static func invalidRow(value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context: EncodingError.Context = .init(codingPath: codingPath, debugDescription: "The CSV row that this container pointed to has been already fully encoded or it is invalid.")
        return EncodingError.invalidValue(value, context)
    }
    
    /// An internal error occurred when trying to write a field.
    /// - parameter field: The raw field value that was going to be writen.
    /// - parameter value: The value from which `field` is distilled.
    /// - parameter codingPath: The full chain of containers till `value`.
    /// - parameter error: The underlying error that has generated the returning error.
    internal static func writingFailed(field: String, value: Any, codingPath: [CodingKey], underlyingError error: Swift.Error?) -> EncodingError {
        let context: EncodingError.Context = .init(codingPath: codingPath, debugDescription: "The field \(field) from \(value) couldn't be writen due to a low-level CSV writer error.", underlyingError: error)
        return EncodingError.invalidValue(value, context)
    }
}
