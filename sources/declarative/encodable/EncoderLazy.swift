import Foundation

extension CSVEncoder {
    /// Lazy encoder allowing declarative row-by-row encoding.
    public final class Lazy<Outcome> {
        /// The sink of the CSV data.
        private let _sink: ShadowEncoder.Sink
        /// The row to be written next.
        private var _currentIndex: Int
        /// A dictionary you use to customize the encoding process by providing contextual information.
        public var userInfo: [CodingUserInfoKey:Any] { self._sink.userInfo }
        
        /// Designated initializer passing all the required components.
        /// - parameter sink: The data _gatherer_ for the encoder.
        internal init(sink: ShadowEncoder.Sink) {
            self._sink = sink
            self._currentIndex = 0
        }
        
        /// Encodes the given value as a CSV row.
        /// - parameter value: The value to encode as CSV.
        public func encodeRow<T:Encodable>(_ value: T) throws {
            let encoder = ShadowEncoder(sink: .passUnretained(self._sink), codingPath: [IndexKey(self._currentIndex)])
            try value.encode(to: encoder)
            self._currentIndex += 1
        }
        
        /// Encodes a row where all its fields are empty.
        public func encodeEmptyRow() throws {
            let numFields = self._sink.numExpectedFields
            guard numFields > 0 else { throw CSVEncoder.Error._invalidRowCompletionOnEmptyFile() }
            
            let encoder = ShadowEncoder(sink: .passUnretained(self._sink), codingPath: [IndexKey(self._currentIndex)])
            var container = ShadowEncoder.UnkeyedContainer(unsafeEncoder: encoder, rowIndex: self._currentIndex)
            for _ in 0..<numFields { try container.encodeNil() }
            self._currentIndex += 1
        }
    }
}

extension CSVEncoder.Lazy where Outcome==Data {
    /// Finish the encoding process and returns the CSV (as a data blob).
    ///
    /// Calls to `encodeRow(_:)` after this function will throw an error.
    public func endEncoding() throws -> Data {
        try self._sink.completeEncoding()
        return try self._sink.data()
    }
}

extension CSVEncoder.Lazy where Outcome==String {
    /// Finish the encoding process and returns the CSV (as a string).
    ///
    /// Calls to `encodeRow(_:)` after this function will throw an error.
    public func endEncoding() throws -> String {
        try self._sink.completeEncoding()
        let data = try self._sink.data()
        let encoding = self._sink.configuration.encoding ?? .utf8
        return String(data: data, encoding: encoding)!
    }
}

extension CSVEncoder.Lazy where Outcome==URL {
    /// Finish the encoding process and closes the output file.
    ///
    /// Calls to `encodeRow(_:)` after this function will throw an error.
    public func endEncoding() throws {
        try self._sink.completeEncoding()
    }
}

// MARK: -

fileprivate extension CSVEncoder.Error {
    /// Error raised when a row is ended, but nothing has been written before.
    static func _invalidRowCompletionOnEmptyFile() -> CSVError<CSVEncoder> {
        .init(.invalidPath,
              reason: "An empty row cannot be encoded if the number of fields hold by the CSV file is unkwnown.",
              help: "Specify a headers row or encode a row with content before encoding an empty row.")
    }
}
