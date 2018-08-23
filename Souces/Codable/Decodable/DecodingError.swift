import Foundation

extension DecodingError {
    /// Error when there is nothing else to parse.
    internal static func isAtEnd(_ type: Any.Type, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "The CSV file or record has already been completely parsed. There is no more data.")
        return DecodingError.valueNotFound(type, context)
    }
    
    /// Error when the CSV has more than a single lonely field.
    internal static func isNotSingleFieldFile(_ type: Any.Type, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "The expectation that the CSV file will contain a single record with a single field were not met.")
        return DecodingError.typeMismatch(type, context)
    }
    
    /// Error when the row is not single column.
    internal static func isNotSingleColumn(_ type: Any.Type, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "The CSV has more than one column. You need to query for another container before start decoding values.")
        return DecodingError.typeMismatch(type, context)
    }
    
    /// Error thrown when the source data being pointed to have change places and cannot be found.
    internal static func invalidDataSource(_ type: Any.Type, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "The pointer to the targeted CSV data have changed and cannot be found.")
        return DecodingError.valueNotFound(type, context)
    }
    
    /// Generates an error expressing the impossibility to create more than two nested containers.
    internal static func invalidNestedContainer(_ type: Any.Type, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "CSV decoders only accept two level of nesting for multiple value container. In other words, you can only called `unkeyedContainer()` or `container(keyedBy:)` twice for a CSV file.")
        return DecodingError.typeMismatch(type, context)
    }
    
    /// The requested container cannot be place in the container chain (codingPath).
    internal static func invalidContainer(codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "The asked decoding container cannot be place in the current codingPath.")
        return DecodingError.typeMismatch(Any.self, context)
    }
    
    /// Generates a *type mismatch* error since the transformation from String to the given type was not possible.
    internal static func mismatchError(string: String, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "The decoded field \"\(string)\" was not of the expected type.")
        return DecodingError.typeMismatch(String.self, context)
    }
    
    /// Generates a *key not found* error since the index requested has already been parsed and there is no way to go backwards.
    internal static func alreadyParsed(key: CodingKey, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "CSV parsing is sequential and the value has already been parsed. There is no way to go backwards.")
        return DecodingError.keyNotFound(key, context)
    }
    
    /// Generates a *key not found* error indicating that the requested key is pointing past the last CSV file's row or the key cannot be transformed into an `Int`.
    internal static func invalidDecodingKey(key: CodingKey, codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "The key requested is invalid; either because it cannot be transformed to an `Int` or it is out of bounds.")
        return DecodingError.keyNotFound(key, context)
    }
}
