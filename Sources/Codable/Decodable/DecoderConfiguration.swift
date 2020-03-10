import Foundation

extension CSVDecoder {
    /// Configuration for how to read CSV data.
    public struct Configuration {
        /// The field and row delimiters.
        public var delimiters: Delimiter.Pair
        /// Indication on whether the CSV will contain a header row, or not, or that information is unknown and it should try to be inferred.
        public var headerStrategy: Strategy.Header
        /// Indication on whether some characters should be trim at reading time.
        public var trimStrategry: Strategy.Trim = .none
        /// The strategy to use when dealing with non-conforming numbers.
        public var floatStrategy: Strategy.NonConformingFloat = .throw
        /// The strategy to use when decoding decimal values.
        public var decimalStrategy: Strategy.DecimalDecoding = .locale(nil)
        /// The strategy to use when decoding dates.
        public var dateStrategy: Strategy.DateDecoding = .deferredToDate
        /// The strategy to use when decoding binary data.
        public var dataStrategy: Strategy.DataDecoding = .base64
        /// The amount of CSV rows kept in memory after decoding to allow the random-order jumping exposed by keyed containers.
        public var bufferingStrategy: Strategy.Buffering = .keepAll
        
        /// General configuration for CSV codecs and parsers.
        /// - parameter fieldDelimiter: The delimiter between CSV fields.
        /// - parameter rowDelimiter: The delimiter between CSV records/rows.
        /// - parameter headerStrategy: Whether the CSV data contains headers at the beginning of the file.
        public init(fieldDelimiter: Delimiter.Field = .comma, rowDelimiter: Delimiter.Row = .lineFeed, headerStrategy: Strategy.Header = .none) {
            self.delimiters = (fieldDelimiter, rowDelimiter)
            self.headerStrategy = headerStrategy
        }
    }
}

extension CSVDecoder.Configuration {
    /// The `CSVReader`'s configuration extracted from the receiving decoder's configuration.
    internal var readerConfiguration: CSVReader.Configuration {
        var result = CSVReader.Configuration(fieldDelimiter: self.delimiters.field, rowDelimiter: self.delimiters.row, headerStrategy: self.headerStrategy)
        result.trimStrategry = self.trimStrategry
        return result
    }
}
