import Foundation

/// Instances of this class are capable of encoding CSV files as described by the `Codable` protocol.
open class CSVEncoder {
    /// Wrap all configurations in a single easy to use structure.
    private var configuration: EncoderConfiguration
    
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
    
    /// The strategy to use in decoding dates.
    ///
    /// Default to however the `Date` initializer works.
    public var dateStrategy: Strategy.DateEncoding {
        get { return self.configuration.dateStrategy }
        set { self.configuration.dateStrategy = newValue }
    }
    
    /// The strategy to use in decoding binary data.
    ///
    /// Defaults to base 64 decoding.
    public var dataStrategy: Strategy.DataEncoding {
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
    public init(configuration: EncoderConfiguration = .init()) {
        self.configuration = configuration
    }
    
    /// Returns a data blob with the provided value encoded as a CSV.
    ///
    /// As optional parameter, the initial data capacity can be set. This doesn’t necessarily allocate the requested memory right away. The function allocates additional memory as needed, so capacity simply establishes the initial capacity. When it does allocate the initial memory, though, it allocates the specified amount.
    ///
    /// If the capacity specified in capacity is greater than four memory pages in size, this may round the amount of requested memory up to the nearest full page.
    /// - parameter value: The value to encode as CSV.
    /// - parameter encoding: The `String` encoding used to encode the `value` into the result (i.e. `Data`).
    open func encode<T:Encodable>(_ value: T, encoding: String.Encoding = .utf8) throws -> Data {
        let output: ShadowEncoder.Output.Request = .data(encoding: encoding)
        let encoder = try ShadowEncoder(output: output, configuration: self.configuration, userInfo: self.userInfo)
        
        try value.encode(to: encoder)
        return try (encoder.output as! ShadowEncoder.Output.DataBlob).data()
    }
    
    /// Writes the given value in the given file URL as a CSV.
    /// - parameter value: The value to encode as CSV.
    /// - parameter url: File URL where the data will be writen (replacing any content in case there were some).
    /// - parameter replacingData: Whether the encoded value should replace the previous content of the file (`true`) or it should add to it (`false`).
    /// - parameter encoding: `String` encoding used in the given file URL. Pass `nil` if you want to use the encoding the file currently have (if it exists).
    open func encode<T:Encodable>(_ value: T, url: URL, replacingData: Bool, encoding: String.Encoding? = nil) throws {
        let output: ShadowEncoder.Output.Request = .file(url: url, replacingData: replacingData, encoding: encoding)
        let encoder = try ShadowEncoder(output: output, configuration: self.configuration, userInfo: self.userInfo)
        
        try value.encode(to: encoder)
        try (encoder.output as! ShadowEncoder.Output.File).close()
    }
}
