import Foundation

/// Configuration for how to parse CSV data.
public struct Configuration {
    /// The field and row delimiters.
    public var delimiters: Delimiter.Pair
    /// Indication on whether the CSV will contain a header row, or not, or that information is unknown and it should try to be inferred.
    public var headerStrategy: Configuration.Strategy.Header
    /// Indication on whether some characters should be trim at reading time.
    public var trimStrategry: Configuration.Strategy.Trim = .none
    /// The strategy to use when dealing with non-conforming numbers.
    public var floatStrategy: Configuration.Strategy.NonConformingFloat = .throw
    /// The strategy to use when decoding dates.
    public var dateDecodingStrategy: Configuration.Strategy.DateDecoding = .deferredToDate
    /// The strategy to use when encoding dates.
    public var dateEncodingStrategy: Configuration.Strategy.DateEncoding = .deferredToDate
    /// The strategy to use when decoding binary data.
    public var dataDecodingStrategy: Configuration.Strategy.DataDecoding = .base64
    /// The strategy to use when encoding binary data.
    public var dataEncodingStrategy: Configuration.Strategy.DataEncoding = .base64
    
    /// General configuration for CSV codecs and parsers.
    /// - parameter headerStrategy: Whether the CSV data contains headers at the beginning of the file.
    /// - parameter trimStrategy: Whether some characters in a set should be trim at the beginning and ending of a CSV field.
    public init(fieldDelimiter: Delimiter.Field = .comma,
                rowDelimiter: Delimiter.Row = .lineFeed,
                headerStrategy: Configuration.Strategy.Header = .none) {
        self.delimiters = (fieldDelimiter, rowDelimiter)
        self.headerStrategy = headerStrategy
    }
}
