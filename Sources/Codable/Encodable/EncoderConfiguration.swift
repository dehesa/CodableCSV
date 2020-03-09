import Foundation

public enum CSVEncoder {}

extension CSVEncoder {
    /// Configuration for how to write CSV data.
    public struct Configuration {
        /// The field and row delimiters.
        public var delimiters: Delimiter.Pair
        /// Indication on whether the CSV will contain a header row, or not, or that information is unknown and it should try to be inferred.
        public var headers: [String]
        /// The strategy to use when dealing with non-conforming numbers.
        public var floatStrategy: Strategy.NonConformingFloat = .throw
        /// The strategy to use when encoding dates.
        public var dateStrategy: Strategy.DateEncoding = .deferredToDate
        /// The strategy to use when encoding binary data.
        public var dataStrategy: Strategy.DataEncoding = .base64
        
        /// General configuration for CSV codecs and parsers.
        /// - parameter fieldDelimiter: The delimiter between CSV fields.
        /// - parameter rowDelimiter: The delimiter between CSV records/rows.
        /// - parameter headerStrategy: Whether the CSV data contains headers at the beginning of the file.
        public init(fieldDelimiter: Delimiter.Field = .comma, rowDelimiter: Delimiter.Row = .lineFeed, headers: [String] = []) {
            self.delimiters = (fieldDelimiter, rowDelimiter)
            self.headers = headers
        }
    }
}

extension CSVEncoder.Configuration {
    /// The `CSVWriter`'s configuration extracted from the receiving encoder's configuration.
    internal var writerConfiguration: CSVWriter.Configuration {
        CSVWriter.Configuration(fieldDelimiter: self.delimiters.field, rowDelimiter: self.delimiters.row, headers: self.headers)
    }
}
