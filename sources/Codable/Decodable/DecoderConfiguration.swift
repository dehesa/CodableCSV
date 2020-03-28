extension CSVDecoder {
    /// Configuration for how to read CSV data.
    @dynamicMemberLookup public struct Configuration {
        /// The underlying `CSVReader` configurations.
        @usableFromInline private(set) internal var readerConfiguration: CSVReader.Configuration
        /// The strategy to use when dealing with non-conforming numbers.
        public var floatStrategy: Strategy.NonConformingFloat
        /// The strategy to use when decoding decimal values.
        public var decimalStrategy: Strategy.DecimalDecoding
        /// The strategy to use when decoding dates.
        public var dateStrategy: Strategy.DateDecoding
        /// The strategy to use when decoding binary data.
        public var dataStrategy: Strategy.DataDecoding
        /// The amount of CSV rows kept in memory after decoding to allow the random-order jumping exposed by keyed containers.
        public var bufferingStrategy: Strategy.DecodingBuffer
        
        /// Designated initializer setting the default values.
        public init() {
            self.readerConfiguration = .init()
            self.floatStrategy = .throw
            self.decimalStrategy = .locale(nil)
            self.dateStrategy = .deferredToDate
            self.dataStrategy = .base64
            self.bufferingStrategy = .keepAll
        }
    }
}

extension CSVDecoder.Configuration {
    /// Gives direct access to all CSV reader's configuration values.
    /// - parameter member: Writable key path for the reader's configuration value.
    public subscript<V>(dynamicMember member: WritableKeyPath<CSVReader.Configuration,V>) -> V {
        @inlinable get { self.readerConfiguration[keyPath: member] }
        set { self.readerConfiguration[keyPath: member] = newValue }
    }
}
