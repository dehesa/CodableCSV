import Foundation

// List of error context reused more than once around the library.
extension DecodingError.Context {
    /// Context indicating that the requested key is pointing past the last CSV file's row or the key cannot be transformed into an `Int`.
    /// - parameter codingPath: The full chain of containers when this error context was generated.
    internal static func invalidKey(codingPath: [CodingKey]) -> DecodingError.Context {
        return .init(codingPath: codingPath, debugDescription: "The key requested is invalid; either because it cannot be transformed to an `Int` or it is out of bounds.")
    }
    
    /// Generates an error expressing the impossibility to create more than two nested containers.
    internal static func invalidNestedContainer(codingPath: [CodingKey]) -> DecodingError.Context {
        return .init(codingPath: codingPath, debugDescription: "CSV decoders only accept two level of nesting for multiple value container. In other words, you can only called `unkeyedContainer()` or `container(keyedBy:)` twice for a CSV file.")
    }
    
    /// Context for errors when the row is not single column.
    /// - parameter codingPath: The full chain of containers when this error context was generated.
    internal static func isNotSingleColumn(codingPath: [CodingKey]) -> DecodingError.Context {
        return .init(codingPath: codingPath, debugDescription: "The CSV has more than one column. You need to query for another container before start decoding values.")
    }
    
    /// Context for errors when the source data being pointed to have change places and cannot be found.
    /// - parameter codingPath: The full chain of containers when this error context was generated.
    internal static func invalidDataSource(codingPath: [CodingKey]) -> DecodingError.Context {
        return .init(codingPath: codingPath, debugDescription: "The pointer to the targeted CSV data have changed and cannot be found.")
    }
    
    /// Context for transfomation errors between `String` and the given type.
    /// - parameter codingPath: The full chain of containers when this error context was generated.
    internal static func invalidTransformation(_ value: String, codingPath: [CodingKey]) -> DecodingError.Context {
        return .init(codingPath: codingPath, debugDescription: "The decoded field \"\(value)\" was not of the expected type.")
    }
    
    
    /// Context for errors generated when there is nothing else to parse.
    /// - parameter codingPath: The full chain of containers when this error context was generated.
    internal static func isAtEnd(codingPath: [CodingKey]) -> DecodingError.Context {
        return .init(codingPath: codingPath, debugDescription: "The CSV file or record has already been completely parsed. There is no more data.")
    }
}
