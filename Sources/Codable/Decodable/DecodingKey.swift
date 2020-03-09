import Foundation

/// The coding key used to identify encoding/decoding containers.
internal struct DecodingKey: CodingKey {
    /// The integer value of the coding key.
    let index: Int
    /// Designated initializer.
    init(_ index: Int) {
        self.index = index
    }
    
    init?(intValue: Int) {
        guard intValue >= 0 else { return nil }
        self.init(intValue)
    }
    
    init?(stringValue: String) {
        guard let intValue = Int(stringValue) else { return nil }
        self.init(intValue)
    }
    
    var stringValue: String {
        return String(self.index)
    }
    
    var intValue: Int? {
        self.index
    }
}

extension DecodingError {
    /// Error occurring when a nested container is requested on an invalid coding path.
    /// - parameter codingPath: The full chain of containers which generated this error.
    static func invalidContainerRequest(codingPath: [CodingKey]) -> DecodingError {
        DecodingError.dataCorrupted(.init(
            codingPath: codingPath,
            debugDescription: "A container cannot be requested matching the coding path"))
    }
    
    /// Error occurring when a coding key representing a row within the CSV file cannot be transformed into an integer value.
    /// - parameter codingPath: The whole coding path, including the invalid row key.
    static func invalidRowKey(codingPath: [CodingKey]) -> DecodingError {
        DecodingError.keyNotFound(codingPath.last!, .init(
            codingPath: codingPath.dropLast(),
            debugDescription: "The provided coding key identifying a row couldn't be transformed into an integer value"))
    }
    
    /// Error occurring when a value is decoded, but a container was expected by the decoder.
    static func invalidNestedRequired(codingPath: [CodingKey]) -> DecodingError {
        DecodingError.dataCorrupted(.init(
            codingPath: codingPath,
            debugDescription: "A nested container is needed to decode CSV row values"))
    }
}

extension DecodingError.Context {
    /// Error occurring when transforming a `String` value into another type.
    /// - parameter value: The `String` value, which couldn't be transformed.
    /// - parameter codingPath: The full chain of containers when this error was generated.
    internal static func invalidTransformation(value: String, codingPath: [CodingKey]) -> DecodingError.Context {
        .init(codingPath: codingPath, debugDescription: "The CSV field '\(value)' was not of the expected type.")
    }
}
