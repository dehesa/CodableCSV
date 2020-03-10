import Foundation

// MARK: - Encoder & Decoder Strategies

/// The strategies to use when encoding/decoding.
public enum Strategy {
    /// The strategy to use for non-standard floating-point values (IEEE 754 infinity and NaN).
    public enum NonConformingFloat {
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        /// Decode the values from the given representation strings.
        case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
}

// MARK: - Decoder Strategies

extension Strategy {
    /// Indication on whether the CSV file contains headers or not.
    public enum Header: ExpressibleByNilLiteral, ExpressibleByBooleanLiteral {
        /// The CSV contains no header row.
        case none
        /// The CSV contains a single header row.
        case firstLine
        /// It is not known whether the CSV contains a header row. Try to infer it!
        case unknown
        
        public init(nilLiteral: ()) { self = .none }
        
        public init(booleanLiteral value: BooleanLiteralType) {
            self = (value) ? .firstLine : .none
        }
    }
    
    /// Indication on whether some character set should be trimmed or not at the beginning and ending of a CSV field.
    public enum Trim: ExpressibleByNilLiteral {
        /// No characters will be trimmed from the input/output.
        case none
        /// White spaces before and after delimiters will be trimmed.
        case whitespaces
        /// The given set of characters will be trimmed before and after delimiters.
        case set(CharacterSet)
        
        public init(nilLiteral: ()) { self = .none }
    }
    
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

// MARK: - Encoder Strategies

extension Strategy {
    /// The strategy to use for encoding `Date` values.
    public enum DateEncoding {
        /// Defer to `Date` for choosing an encoding.
        case deferredToDate
        /// Encode the `Date` as a UNIX timestamp (as a number).
        case secondsSince1970
        /// Encode the `Date` as UNIX millisecond timestamp (as a number).
        case millisecondsSince1970
        /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        case iso8601
        /// Encode the `Date` as a string formatted by the given formatter.
        case formatted(DateFormatter)
        /// Encode the `Date` as a custom value encoded by the given closure.
        ///
        /// If the closure fails to encode a value into the given encoder, the encoder will encode an empty automatic container in its place.
        case custom((Date, Encoder) throws -> Void)
    }
    
    /// The strategy to use for encoding `Data` values.
    public enum DataEncoding {
        /// Defer to `Data` for choosing an encoding.
        case deferredToData
        /// Encoded the `Data` as a Base64-encoded string.
        case base64
        /// Encode the `Data` as a custom value encoded by the given closure.
        ///
        /// If the closure fails to encode a value into the given encoder, the encoder will encode an empty automatic container in its place.
        case custom((Data, Encoder) throws -> Void)
    }
}
