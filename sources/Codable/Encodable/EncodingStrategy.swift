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
}

extension CSVEncoder: Failable {
    /// The type of error raised by the CSV writer.
    public enum Error: Int {
        /// The encoding coding path is invalid.
        case invalidPath = 2
    }
    
    public static var errorDomain: String { "Writer" }
    
    public static func errorDescription(for failure: Error) -> String {
        switch failure {
        case .invalidPath: return "Invalid coding path"
        }
    }
}
