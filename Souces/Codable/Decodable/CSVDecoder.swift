import Foundation

/// An object that decodes instances of a data type from CSV file content..
open class CSVDecoder {
    /// Wrap all configurations in a single easy to use structure.
    private var configuration: CSV.Configuration
    
    /// The field and row delimiters.
    ///
    /// Defaults to a comma for field delimiter and a line feed for a row delimiter.
    public var delimiters: CSV.Delimiter.Pair {
        get { return self.configuration.delimiters }
        set { self.configuration.delimiters = newValue }
    }
    
    /// Whether the CSV data contains headers at the beginning of the file.
    ///
    /// Defaults to "no header".
    public var headerStrategy: CSV.Strategy.Header {
        get { return self.configuration.headerStrategy }
        set { self.configuration.headerStrategy = newValue }
    }
    
    /// Indication on whether the beginnings and endings of a field should be trimmed and what characters exactly.
    ///
    /// Defaults to "no character trimming".
    public var trimStrategy: CSV.Strategy.Trim {
        get { return self.configuration.trimStrategry }
        set { self.configuration.trimStrategry = newValue }
    }
    
    /// The strategy to use in decoding dates.
    ///
    /// Default to however the `Date` initializer works.
    public var dateStrategy: CSV.Strategy.Date {
        get { return self.configuration.dateStrategy }
        set { self.configuration.dateStrategy = newValue }
    }
    
    /// The strategy to use in decoding binary data.
    ///
    /// Defaults to base 64 decoding.
    public var dataStrategy: CSV.Strategy.Data {
        get { return self.configuration.dataStrategy }
        set { self.configuration.dataStrategy = newValue }
    }
    
    /// The strategy to use in decoding non-conforming numbers.
    ///
    /// Defaults to throw when confronting non-conforming numbers.
    public var nonConfirmingFloatStrategy: CSV.Strategy.NonConformingFloat {
        get { return self.configuration.floatStrategy }
        set { self.configuration.floatStrategy = newValue }
    }
    
    /// A dictionary you use to customize the decoding process by providing contextual information.
    open var userInfo: [CodingUserInfoKey:Any] = [:]

    /// Designated initializer specifying default values for the parser.
    public init(configuration: CSV.Configuration = .init()) {
        self.configuration = configuration
    }

    /// Returns a value of the type you specify decoded from a CSV file.
    /// - parameter type: The type of the value to decode from the supplied file.
    /// - parameter data: The file content to decode.
    /// - parameter encoding: The encoding used on the provided `data`. If `nil` is passed, the decoder will try to infer it.
    /// - throws: `DecodingError` exclusively. Many errors will have a `CSVReader.Error` *underlying error* containing further information.
    /// - note: The encoding inferral process may take a lot of processing power if your data blob is big. Try to always input the encoding if you know it beforehand.
    open func decode<T:Decodable>(_ type: T.Type, from data: Data, encoding: String.Encoding? = .utf8) throws -> T {
        // Try to figure out the data encoding if it is not indicated.
        guard let inferredEncoding = encoding ?? data.inferEncoding() else {
            let underlyingError = CSVReader.Error.unsuccessfulInferral(message: "The encoding for the data blob couldn't be inferred.")
            let context = DecodingError.Context(codingPath: [], debugDescription: "CSV encoding couldn't be inferred.", underlyingError: underlyingError)
            throw DecodingError.dataCorrupted(context)
        }
        
        let decoder = try ShadowDecoder(data: data, encoding: inferredEncoding, configuration: self.configuration, userInfo: self.userInfo)
        return try T(from: decoder)
    }
}
