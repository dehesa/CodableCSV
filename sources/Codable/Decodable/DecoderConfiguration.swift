import Foundation

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

// MARK: -

extension Strategy {
    /// The strategy to use for decoding `Decimal` values.
    public enum DecimalDecoding {
        /// The locale used to interpret the number (specifically `decimalSeparator`).
        case locale(Locale? = nil)
        /// Decode the `Decimal` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Decimal)
    }
    
    /// The strategy to use for decoding `Date` values.
    public enum DateDecoding {
        /// Defer to `Date` for decoding.
        case deferredToDate
        /// Decode the `Date` as a UNIX timestamp from a number.
        case secondsSince1970
        /// Decode the `Date` as UNIX millisecond timestamp from a number.
        case millisecondsSince1970
        /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        case iso8601
        /// Decode the `Date` as a string parsed by the given formatter.
        case formatted(DateFormatter)
        /// Decode the `Date` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Date)
    }
    
    /// The strategy to use for decoding `Data` values.
    public enum DataDecoding {
        /// Defer to `Data` for decoding.
        case deferredToData
        /// Decode the `Data` from a Base64-encoded string.
        case base64
        /// Decode the `Data` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Data)
    }
    
    /// Indication of how many rows are cached for reuse by the decoder.
    ///
    /// CSV decoding is an inherently sequential operation; i.e. row 2 must be decoded after row 1. This due to the string encoding, the field/row delimiter usage, and by not setting the underlying row width.
    /// On the other hand, the `Decodable` protocol allows CSV rows to be decoded in random-order through the keyed containers. For example, a user can ask for a row at position 24 and then ask for the CSV row at index 3.
    ///
    /// A buffer is used to marry the sequential needs of the CSV decoder and `Decodable`'s *random* nature. This buffer stores all decoded CSV rows (starts with none and gets filled as more rows are being decoded).
    /// The `DecodingBuffer` strategy gives you the option to control the buffer's memory usage and whether rows are being discarded after being decoded.
    public enum DecodingBuffer {
        /// All decoded CSV rows are cached.
        /// Forward/Backwards decoding jumps are allowed. A row that has been previously decoded can be decoded again.
        ///
        /// Setting this strategy will double the memory usage, but the user is free to request rows in any order.
        case keepAll
        /// Only CSV rows that have been decoded but not requested by the user are being kept in memory.
        /// Forward/Backwards decoding jumps are allowed. However, previously requested rows cannot be requested again or an error will be thrown.
        ///
        /// This strategy will massively reduce the memory usage, but it will throw an error if a CSV row that was previously decoded is requested from a keyed container.
        case assembled
        /// No rows are kept in memory (except for the CSV row being decoded at the moment)
        /// Forward jumps are allowed, but the rows in-between the jump cannot be decoded.
        case sequential
    }
}

