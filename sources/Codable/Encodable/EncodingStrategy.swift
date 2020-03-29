import Foundation

extension Strategy {
    /// The strategy to use for encoding `Decimal` values.
    public enum DecimalEncoding {
        /// The locale used to write the number (specifically the `decimalSeparator` property).
        case locale(Locale?)
        /// Encode the `Decimal` as a custom value encoded by the given closure.
        ///
        /// If the closure fails to encode a value into the given encoder, the encoder will buble up the error.
        case custom((Decimal, Encoder) throws -> Void)
    }
    
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
        /// If the closure fails to encode a value into the given encoder, the encoder will buble up the error.
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
    
    /// Indication on how encoded CSV rows are cached and actually written to the output target (file, data blocb, or string).
    ///
    /// CSV encoding is an inherently sequential operation, i.e. row 2 must be encoded after row 1. On the other hand, the `Encodable` protocol allows CSV rows to be encoded in a random-order
    public enum EncodingBuffer {
        /// Encoded rows are being kept in memory till it is their turn to be written to the targeted output.
        ///
        /// Foward encoding jumps are allowed and the user may jump backward to continue encoding.
        case unfulfilled
        /// No rows are kept in memory and writes are performed sequentially.
        ///
        /// If a keyed container is used to encode rows and a jump forward is requested all the in-between rows are filled with empty fields.
        case sequential
    }
}

extension CSVEncoder: Failable {
    /// The type of error raised by the CSV writer.
    public enum Error: Int {
        /// Some of the configuration values provided are invalid.
        case invalidConfiguration = 1
        /// The encoding coding path is invalid.
        case invalidPath = 2
        /// An error occurred on the encoder buffer.
        case bufferFailure = 4
    }
    
    public static var errorDomain: String { "Writer" }
    
    public static func errorDescription(for failure: Error) -> String {
        switch failure {
        case .invalidConfiguration: return "Invalid configuration"
        case .invalidPath: return "Invalid coding path"
        case .bufferFailure: return "Invalid buffer state"
        }
    }
}
