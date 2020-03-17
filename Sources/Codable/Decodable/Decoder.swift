import Foundation

/// Instances of this class are capable of decoding CSV files as described by the `Codable` protocol.
open class CSVDecoder {
    /// Wrap all configurations in a single easy-to-use structure.
    private var configuration: Configuration
    
    /// The field and row delimiters.
    ///
    /// Defaults to "comma" (i.e. `,`) for field delimiter and "line feed" (i.e. `\n`) for a row delimiter.
    public var delimiters: Delimiter.Pair {
        get { return self.configuration.delimiters }
        set { self.configuration.delimiters = newValue }
    }
    
    /// Whether the CSV data contains headers at the beginning of the file.
    ///
    /// Defaults to "no header".
    public var headerStrategy: Strategy.Header {
        get { return self.configuration.headerStrategy }
        set { self.configuration.headerStrategy = newValue }
    }
    
    /// Indication on whether the beginnings and endings of a field should be trimmed and what characters exactly.
    ///
    /// Defaults to "no character trimming".
    public var trimStrategy: CharacterSet {
        get { return self.configuration.trimStrategry }
        set { self.configuration.trimStrategry = newValue }
    }
    
    /// The strategy to use in decoding dates.
    ///
    /// Default to however the `Date` initializer works.
    public var dateStrategy: Strategy.DateDecoding {
        get { return self.configuration.dateStrategy }
        set { self.configuration.dateStrategy = newValue }
    }
    
    /// The strategy to use in decoding binary data.
    ///
    /// Defaults to base 64 decoding.
    public var dataStrategy: Strategy.DataDecoding {
        get { return self.configuration.dataStrategy }
        set { self.configuration.dataStrategy = newValue }
    }
    
    /// The strategy to use in decoding non-conforming numbers.
    ///
    /// Defaults to throw when confronting non-conforming numbers.
    public var nonConfirmingFloatStrategy: Strategy.NonConformingFloat {
        get { return self.configuration.floatStrategy }
        set { self.configuration.floatStrategy = newValue }
    }
    
    /// A dictionary you use to customize the decoding process by providing contextual information.
    open var userInfo: [CodingUserInfoKey:Any] = [:]

    /// Designated initializer specifying default configuration values for the parser.
    /// - parameter configuration: Optional configuration values for the decoding process.
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    /// Convenience initializer passing the most used configuration values.
    /// - parameter fieldDelimiter: The delimiter between CSV fields.
    /// - parameter rowDelimiter: The delimiter between CSV records/rows.
    /// - parameter headerStrategy: Whether the CSV data contains headers at the beginning of the file.
    public convenience init(fieldDelimiter: Delimiter.Field = ",", rowDelimiter: Delimiter.Row = "\n", headerStrategy: Strategy.Header = .none) {
        self.init(configuration: .init(fieldDelimiter: fieldDelimiter, rowDelimiter: rowDelimiter, headerStrategy: headerStrategy))
    }

    /// Returns a value of the type you specify decoded from a CSV file.
    /// - parameter type: The type of the value to decode from the supplied file.
    /// - parameter data: The file content to decode.
    /// - parameter encoding: The encoding used on the provided `data`. If `nil` is passed, the decoder will try to infer it.
    /// - note: The encoding inferral process may take a lot of processing power if your data blob is big. Try to always input the encoding if you know it beforehand.
    open func decode<T:Decodable>(_ type: T.Type, from data: Data, encoding: String.Encoding? = .utf8) throws -> T {
//        #warning("Implement me")
        fatalError()
//        // Try to figure out the data encoding if it is not indicated.
//        guard let inferredEncoding = encoding ?? data.inferEncoding() else {
//            let underlyingError = CSVReader.Error(.inferenceFailure, reason: "The encoding for the data blob couldn't be inferred.", help: "Set a explicit encoding")
//            let context = DecodingError.Context(codingPath: [], debugDescription: "CSV encoding couldn't be inferred.", underlyingError: underlyingError)
//            throw DecodingError.dataCorrupted(context)
//        }
//        
//        let decoder = try ShadowDecoder(data: data, encoding: inferredEncoding, configuration: self.configuration, userInfo: self.userInfo)
//        return try T(from: decoder)
    }
}
