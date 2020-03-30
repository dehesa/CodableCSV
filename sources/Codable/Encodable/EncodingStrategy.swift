import Foundation

extension Strategy {
    /// The strategy to use for encoding `Decimal` values.
    public enum DecimalEncoding {
        /// The locale used to write the number (specifically the `decimalSeparator` property).
        case locale(Locale? = nil)
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
    
    /// Indication on how encoded CSV rows are cached and written to the output target (file, data blocb, or string).
    ///
    /// CSV encoding is an inherently sequential operation, i.e. row 2 must be encoded after row 1. On the other hand, the `Encodable` protocol allows CSV rows to be encoded in a random-order through *keyed container*. Selecting the appropriate buffering strategy lets you pick your encoding style and minimize memory usage.
    public enum EncodingBuffer {
        /// All encoded rows/fields are cached and the *writing* only occurs at the end of the encodable process.
        ///
        /// *Keyed containers* can be used to encode rows/fields unordered. That means, a row at position 5 may be encoded before the row at position 3. Similar behavior is supported for fields within a row.
        /// - attention: This strategy consumes the largest amount of memory from all the supported options.
        case keepAll
        /// Encoded rows may be cached, but the encoder will keep the buffer as small as possible by writing completed ordered rows.
        ///
        /// *Keyed containers* can be used to encode rows/fields unordered. The writer will however consume rows in order.
        ///
        /// For example, an encoder starts encoding row 1 and it gets all its fields. The row will get written and no cache for the row is kept. Same situation occurs when the row 2 is encoded.
        /// However, the user may decide to jump to row 5 and encode it. This row will be kept in the cache till row 3 and 4 are encoded, at which time row 3, 4, 5, and any subsequent rows will be writen.
        /// - attention: This strategy tries to keep the cache to a minimum, but memory usage may be big if there are holes while encoding rows. Those holes are filled with empty rows at the end of the encoding process.
        case unfulfilled
        /// No rows are kept in memory and writes are performed sequentially.
        ///
        /// *Keyed containers* can be used, however when forward jumps are performed any in-between rows will be filled with empty fields.
        /// - attention: This strategy provides the smallest usage of memory from all.
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
