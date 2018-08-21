import Foundation

/// An object that decodes instances of a data type from CSV file content..
public final class CSVDecoder {
    /// The field and row delimiters.
    ///
    /// By default, it is a comma for fields and a carriage return + line feed for a row.
    public var delimiters: CSV.Delimiter.Pair = (.comma, .lineFeed)
    /// Whether the CSV data contains headers at the beginning of the file.
    public var headerStrategy: CSV.Strategy.Header = .none
    /// Indication on whether the beginnings and endings of a field should be trimmed and what characters exactly.
    public var trimStrategy: CSV.Strategy.Trim = .none
    /// A dictionary you use to customize the decoding process by providing contextual information.
    public var userInfo: [CodingUserInfoKey:Any] = [:]

    /// Designated initializer specifying default values for the parser.
    public init() {}

    /// Returns a value of the type you specify decoded from a CSV file.
    /// - parameter type: The type of the value to decode from the supplied file.
    /// - parameter data: The file content to decode.
    /// - parameter encoding: The encoding used on the provided `data`. If `nil` is passed, the decoder will try to infer it.
    /// - throws: `DecodingError` exclusively. Many errors will have a `CSVReader.Error` *underlying error* containing further information.
    /// - note: The encoding inferral process may take a lot of processing power if your data blob is big. Try to always input the encoding if you know it beforehand.
    public func decode<T:Decodable>(_ type: T.Type, from data: Data, encoding: String.Encoding? = .utf8) throws -> T {
        // Try to figure out the data encoding if it is not indicated.
        guard let inferredEncoding = encoding ?? data.inferEncoding() else {
            let underlyingError = CSVReader.Error.unsuccessfulInferral(message: "The encoding for the data blob couldn't be inferred.")
            let context = DecodingError.Context(codingPath: [], debugDescription: "CSV encoding couldn't be inferred.", underlyingError: underlyingError)
            throw DecodingError.dataCorrupted(context)
        }
        
        let config = CSV.Configuration(fieldDelimiter: delimiters.field, rowDelimiter: delimiters.row, headerStrategy: headerStrategy, trimStrategy: trimStrategy)
        let decoder = try ShadowDecoder(data: data, encoding: inferredEncoding, configuration: config, userInfo: userInfo)
        return try T(from: decoder)
    }
}
