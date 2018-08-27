import Foundation

extension CSV {
    /// Configuration for how to parse CSV data.
    public struct Configuration {
        /// The field and row delimiters.
        public var delimiters: CSV.Delimiter.Pair
        /// Indication on whether the CSV will contain a header row, or not, or that information is unknown and it should try to be inferred.
        public var headerStrategy: CSV.Strategy.Header
        /// Indication on whether some characters should be trim at reading time.
        public var trimStrategry: CSV.Strategy.Trim
        /// The strategy to use when dealing with non-conforming numbers.
        public var floatStrategy: CSV.Strategy.NonConformingFloat
        /// The strategy to use when dealing with dates.
        public var dateStrategy: CSV.Strategy.Date
        /// The strategy to use when dealing with binary data.
        public var dataStrategy: CSV.Strategy.Data
        
        /// General configuration for CSV codecs and parsers.
        /// - parameter headerStrategy: Whether the CSV data contains headers at the beginning of the file.
        /// - parameter trimStrategy: Whether some characters in a set should be trim at the beginning and ending of a CSV field.
        public init(fieldDelimiter: CSV.Delimiter.Field = .comma,
                    rowDelimiter: CSV.Delimiter.Row = .lineFeed,
                    headerStrategy: CSV.Strategy.Header = .none,
                    trimStrategy: CSV.Strategy.Trim = .none,
                    floatStrategy: CSV.Strategy.NonConformingFloat = .throw,
                    dateStrategy: CSV.Strategy.Date = .deferredToDate,
                    dataStrategy: CSV.Strategy.Data = .base64) {
            self.delimiters = (fieldDelimiter, rowDelimiter)
            self.headerStrategy = headerStrategy
            self.trimStrategry = trimStrategy
            self.floatStrategy = floatStrategy
            self.dateStrategy = dateStrategy
            self.dataStrategy = dataStrategy
        }
    }
}
