extension CSVEncoder {
    /// Configuration for how to write CSV data.
   @dynamicMemberLookup public struct Configuration {
        /// The underlying `CSVWriter` configurations.
        @usableFromInline private(set) internal var writerConfiguration: CSVWriter.Configuration
        /// The strategy to use when dealing with non-conforming numbers.
        public var floatStrategy: Strategy.NonConformingFloat
        /// The strategy to use when encoding decimal values.
        public var decimalStrategy: Strategy.DecimalEncoding
        /// The strategy to use when encoding dates.
        public var dateStrategy: Strategy.DateEncoding
        /// The strategy to use when encoding binary data.
        public var dataStrategy: Strategy.DataEncoding
        /// Indication on how encoded CSV rows are cached and actually written to the output target.
        public var bufferingStrategy: Strategy.EncodingBuffer
        
        /// Designated initializer setting the default values.
        public init() {
            self.writerConfiguration = .init()
            self.floatStrategy = .throw
            self.decimalStrategy = .locale(nil)
            self.dateStrategy = .deferredToDate
            self.dataStrategy = .base64
            self.bufferingStrategy = .keepAll
        }
    }
}

extension CSVEncoder.Configuration {
    /// Gives direct access to all CSV writer's configuration values.
    /// - parameter member: Writable key path for the writer's configuration values.
    public subscript<V>(dynamicMember member: WritableKeyPath<CSVWriter.Configuration,V>) -> V {
        @inlinable get { self.writerConfiguration[keyPath: member] }
        set { self.writerConfiguration[keyPath: member] = newValue }
    }
}
