import Foundation

extension Strategy {
    /// The strategy to use for decoding `Decimal` values.
    public enum DecimalDecoding {
        /// The locale used to interpret the number (specifically `decimalSeparator`).
        case locale(Locale?)
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
    
    /// Strategy indicating how many rows are cached for reuse by the decoder.
    ///
    /// The `Decodable` protocol allows CSV rows to be decoded in random-order through the keyed containers. For example, a user can ask for a row at position 24 and then ask for the CSV row at index 1.
    /// Since it is impossible to foresee how the user will decode the rows, this library allows the user to set the buffering mechanism.
    ///
    /// Setting the buffering strategy lets you tweak the memory usage and whether an error will be thrown when previous rows are requested:
    /// - `keepAll` will impose no restrictions and will make the decoder cache every decoded row. Setting this strategy will double the memory usage, but the user is free to request rows in any order.
    /// - `ordered` discard decoded rows after usage, only keeping records when a jump forward have been requested through a keyed container.
    public enum Buffering {
        /// All decoded CSV rows are cached.
        case keepAll
        /// Rows are only cached when there are holes between the decoded row indices.
        case ordered
    }
}
