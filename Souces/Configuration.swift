import Foundation

/// Basic CSV configuration.
public protocol Configuration {
    /// The field and row delimiters.
    var delimiters: Delimiter.Pair { get set }
    /// The strategy to use when dealing with non-conforming numbers.
    var floatStrategy: Strategy.NonConformingFloat { get set }
    
    /// Default configuration.
    init()
}

/// Configuration for how to read CSV data.
public struct DecoderConfiguration: Configuration {
    public var delimiters: Delimiter.Pair = (.comma, .lineFeed)
    public var floatStrategy: Strategy.NonConformingFloat = .throw
    
    /// Indication on whether the CSV will contain a header row, or not, or that information is unknown and it should try to be inferred.
    public var headerStrategy: Strategy.Header = .none
    /// Indication on whether some characters should be trim at reading time.
    public var trimStrategry: Strategy.Trim = .none
    /// The strategy to use when decoding dates.
    public var dateStrategy: Strategy.DateDecoding = .deferredToDate
    /// The strategy to use when decoding binary data.
    public var dataStrategy: Strategy.DataDecoding = .base64
    
    public init() {}
    
    /// General configuration for CSV codecs and parsers.
    /// - parameter fieldDelimiter: The delimiter between CSV fields.
    /// - parameter rowDelimiter: The delimiter between CSV records/rows.
    /// - parameter headerStrategy: Whether the CSV data contains headers at the beginning of the file.
    public init(fieldDelimiter: Delimiter.Field, rowDelimiter: Delimiter.Row, headerStrategy: Strategy.Header) {
        self.delimiters = (fieldDelimiter, rowDelimiter)
        self.headerStrategy = headerStrategy
    }
}

/// Configuration for how to write CSV data.
public struct EncoderConfiguration: Configuration {
    public var delimiters: Delimiter.Pair = (.comma, .lineFeed)
    public var floatStrategy: Strategy.NonConformingFloat = .throw
    
    /// Indication on whether the CSV will contain a header row, or not, or that information is unknown and it should try to be inferred.
    public var headers: [String] = .init()
    /// The strategy to use when encoding dates.
    public var dateStrategy: Strategy.DateEncoding = .deferredToDate
    /// The strategy to use when encoding binary data.
    public var dataStrategy: Strategy.DataEncoding = .base64
    
    public init() {}
    
    /// General configuration for CSV codecs and parsers.
    /// - parameter fieldDelimiter: The delimiter between CSV fields.
    /// - parameter rowDelimiter: The delimiter between CSV records/rows.
    /// - parameter headerStrategy: Whether the CSV data contains headers at the beginning of the file.
    public init(fieldDelimiter: Delimiter.Field, rowDelimiter: Delimiter.Row, headers: [String]?) {
        self.delimiters = (fieldDelimiter, rowDelimiter)
        self.headers = headers ?? []
    }
}
