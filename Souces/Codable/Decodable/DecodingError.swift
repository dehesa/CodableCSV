import Foundation

extension DecodingError {
    /// Error when there is nothing else to parse.
    internal static func isAtEnd(_ type: Any.Type, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "The CSV file or record has already been completely parsed. There is no more data.")
        return DecodingError.valueNotFound(type, context)
    }
    
    /// Error when the row is not single column.
    internal static func isNotSingleColumn(_ type: Any.Type, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "The CSV has more than one column. You need to query for another container before start decoding values.")
        return DecodingError.typeMismatch(type, context)
    }
    
    /// Generates an error expressing the impossibility to create more than a `FileContainer` and a `RowContainer`.
    internal static func invalidNestedContainer(_ type: Any.Type, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "CSV decoders only accept two level of nesting for multiple value container. In other words, you can only called `unkeyedContainer()` or `container(keyedBy:)` twice for a CSV file.")
        return DecodingError.typeMismatch(type, context)
    }
    
    /// Generates a *type mismatch* error since the transformation from String to the given type was not possible.
    internal static func mismatchError(string: String, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "The decoded field \"\(string)\" was not of the expected type.")
        return DecodingError.typeMismatch(String.self, context)
    }
}
