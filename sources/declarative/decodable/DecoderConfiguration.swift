import Foundation

extension CSVDecoder {
    /// Configuration for how to read CSV data.
    @dynamicMemberLookup public struct Configuration {
        /// The underlying `CSVReader` configurations.
        @usableFromInline internal private(set) var readerConfiguration: CSVReader.Configuration
        /// The strategy to use when decoding a `nil` representation.
        public var nilStrategy: Strategy.NilDecoding
        /// The strategy to use when decoding Boolean values.
        public var boolStrategy: Strategy.BoolDecoding
        /// The strategy to use when dealing with non-conforming numbers.
        public var nonConformingFloatStrategy: Strategy.NonConformingFloat
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
            self.nilStrategy = .empty
            self.boolStrategy = .insensitive
            self.nonConformingFloatStrategy = .throw
            self.decimalStrategy = .locale(nil)
            self.dateStrategy = .deferredToDate
            self.dataStrategy = .base64
            self.bufferingStrategy = .keepAll
        }
        
        /// Gives direct access to all CSV reader's configuration values.
        /// - parameter member: Writable key path for the reader's configuration value.
        public subscript<V>(dynamicMember member: WritableKeyPath<CSVReader.Configuration,V>) -> V {
            @inlinable get { self.readerConfiguration[keyPath: member] }
            set { self.readerConfiguration[keyPath: member] = newValue }
        }
    }
}

extension Strategy {
    /// The strategy to use for decoding `nil` representations.
    public enum NilDecoding {
        /// An empty string is considered a `nil` value.
        ///
        /// An empty string can be both the absence of characters between field delimiters and an empty escaped field (e.g. `""`).
        case empty
        /// Decodes the `nil` as a custom value decoded by the given closure.
        ///
        /// Custom `nil` decoding adheres to the same behavior as a custom `Decodable` type. For example:
        ///
        ///     let decoder = CSVDecoder()
        ///     decoder.nilStrategy = .custom({
        ///         let container = try $0.singleValueContainer()
        ///         let string = try container.decode(String.self)
        ///         return string == "-"
        ///     })
        ///
        /// - parameter decoding: Function receiving the CSV decoder used to parse a custom `nil` value.
        /// - parameter decoder: The decoder on which to fetch a single value container to obtain the underlying `String` value.
        /// - returns: Boolean indicating whether the encountered value was a `nil` representation. If the value is not supported, return `false`.
        case custom(_ decoding: (_ decoder: Decoder) -> Bool)
    }
    
    /// The strategy to use for decoding `Bool` values.
    public enum BoolDecoding {
        /// Defer to `Bool`'s `LosslessStringConvertible` initializer.
        ///
        /// For a value to be considered `true` or `false`, it must be a string with the exact value of `"true"` or `"false"`.
        case deferredToBool
        /// Decodes a Boolean from an underlying string value by transforming `true`/`false` and `yes`/`no` disregarding case sensitivity.
        ///
        /// The value: `True`, `TRUE`, `TruE` or `YES`are accepted.
        case insensitive
        /// Decodes the `Bool` from an underlying `0` or `1`
        case numeric
        /// Decodes the `Bool` as a custom value decoded by the given closure. If the closure fails to decode a value from the given decoder, the error will be bubled up.
        ///
        /// Custom `Bool` decoding adheres to the same behavior as a custom `Decodable` type. For example:
        ///
        ///     let decoder = CSVDecoder()
        ///     decoder.boolStrategy = .custom({
        ///         let container = try $0.singleValueContainer()
        ///         switch try container.decode(String.self) {
        ///         case "si": return true
        ///         case "no": return false
        ///         default: throw CSVError<CSVDecoder>(...)
        ///         }
        ///     })
        ///
        /// - parameter decoding: Function receiving the CSV decoder used to parse a custom `Bool` value.
        /// - parameter decoder: The decoder on which to fetch a single value container to obtain the underlying `String` value.
        /// - returns: Boolean value decoded from the underlying storage.
        case custom(_ decoding: (_ decoder: Decoder) throws -> Bool)
    }
    
    /// The strategy to use for decoding `Decimal` values.
    public enum DecimalDecoding {
        /// The locale used to interpret the number (specifically `decimalSeparator`).
        case locale(Locale? = nil)
        /// Decode the `Decimal` as a custom value decoded by the given closure. If the closure fails to decode a value from the given decoder, the error will be bubled up.
        ///
        /// Custom `Decimal` decoding adheres to the same behavior as a custom `Decodable` type. For example:
        ///
        ///     let decoder = CSVDecoder()
        ///     decoder.decimalStrategy = .custom({
        ///         let value = try Float(from: decoder)
        ///         return Decimal(value)
        ///     })
        ///
        /// - parameter decoding: Function receiving the CSV decoder used to parse a custom `Decimal` value.
        /// - parameter decoder: The decoder on which to fetch a single value container to obtain the underlying `String` value.
        /// - returns: `Decimal` value decoded from the underlying storage.
        case custom(_ decoding: (_ decoder: Decoder) throws -> Decimal)
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
        /// Decode the `Date` as a custom value decoded by the given closure. If the closure fails to decode a value from the given decoder, the error will be bubled up.
        ///
        /// Custom `Date` decoding adheres to the same behavior as a custom `Decodable` type. For example:
        ///
        ///     let decoder = CSVDecoder()
        ///     decoder.dateStrategy = .custom({
        ///         let container = try $0.singleValueContainer()
        ///         let string = try container.decode(String.self)
        ///         // Now returns the date represented by the custom string or throw an error if the string cannot be converted to a date.
        ///     })
        ///
        /// - parameter decoding: Function receiving the CSV decoder used to parse a custom `Date` value.
        /// - parameter decoder: The decoder on which to fetch a single value container to obtain the underlying `String` value.
        /// - returns: `Date` value decoded from the underlying storage.
        case custom(_ decoding: (_ decoder: Decoder) throws -> Date)
    }
    
    /// The strategy to use for decoding `Data` values.
    public enum DataDecoding {
        /// Defer to `Data` for decoding.
        case deferredToData
        /// Decode the `Data` from a Base64-encoded string.
        case base64
        /// Decode the `Data` as a custom value decoded by the given closure. If the closure fails to decode a value from the given decoder, the error will be bubled up.
        ///
        /// Custom `Data` decoding adheres to the same behavior as a custom `Decodable` type. For example:
        ///
        ///     let decoder = CSVDecoder()
        ///     decoder.dataStrategy = .custom({
        ///         let container = try $0.singleValueContainer()
        ///         let string = try container.decode(String.self)
        ///         // Now returns the data represented by the custom string or throw an error if the string cannot be converted to a data.
        ///     })
        ///
        /// - parameter decoding: Function receiving the CSV decoder used to parse a custom `Data` value.
        /// - parameter decoder: The decoder on which to fetch a single value container to obtain the underlying `String` value.
        /// - returns: `Data` value decoded from the underlying storage.
        case custom(_ decoding: (_ decoder: Decoder) throws -> Data)
    }
    
    /// Indication of how many rows are cached for reuse by the decoder.
    ///
    /// CSV decoding is an inherently sequential operation; i.e. row 2 must be decoded after row 1. This due to the string encoding, the field/row delimiter usage, and by not setting the underlying row width.
    /// On the other hand, the `Decodable` protocol allows CSV rows to be decoded in random-order through the keyed containers. For example, a user can ask for a row at position 24 and then ask for the CSV row at index 3.
    ///
    /// A buffer is used to marry the sequential needs of the CSV decoder and `Decodable`'s _random-access_ nature. This buffer stores all decoded CSV rows (starts with none and gets filled as more rows are being decoded).
    /// The `DecodingBuffer` strategy gives you the option to control the buffer's memory usage and whether rows are being discarded after being decoded.
    public enum DecodingBuffer {
        /// All decoded CSV rows are cached.
        /// Forward/Backwards decoding jumps are allowed. A row that has been previously decoded can be decoded again.
        /// - remark: This strategy consumes the largest amount of memory from all the supported options.
        case keepAll
//        /// Only CSV fields that have been decoded but not requested by the user are being kept in memory.
//        ///
//        /// _Keyed containers_ can be used to read rows/fields unordered. However, previously requested rows cannot be requested again or an error will be thrown.
//        /// - remark: This strategy tries to keep the cache to a minimum, but memory usage may be big if the user doesn't request intermediate rows.
//        case unrequested
        /// No rows are kept in memory (except for the CSV row being decoded at the moment)
        ///
        /// _Keyed containers_ can be used, but at a file-level any forward jump will discard the in-between rows. At a row-level _keyed containers_ may still be used for random-order reading.
        /// - remark: This strategy provides the smallest usage of memory from them all.
        case sequential
    }
}

// MARK: -

extension CSVDecoder: Failable {
    /// The type of error raised by the CSV decoder.
    public enum Error: Int {
        /// Some of the configuration values provided are invalid.
        case invalidConfiguration = 1
        /// The decoding coding path is invalid.
        case invalidPath = 2
        /// An error occurred on the encoder buffer.
        case bufferFailure = 4
    }
    
    public static var errorDomain: String {
        "Decoder"
    }
    
    public static func errorDescription(for failure: Error) -> String {
        switch failure {
        case .invalidConfiguration: return "Invalid configuration"
        case .invalidPath: return "Invalid path"
        case .bufferFailure: return "Invalid buffer state"
        }
    }
}
