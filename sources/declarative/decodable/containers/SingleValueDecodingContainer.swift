import Foundation

extension ShadowDecoder {
    /// Single value container for the CSV shadow decoder.
    internal struct SingleValueContainer: SingleValueDecodingContainer {
        /// The representation of the decoding process point-in-time.
        private let _decoder: ShadowDecoder
        /// The container's target (or level).
        private let _focus: _Focus
        
        /// Fast initializer that doesn't perform any checks on the coding path (assuming it is valid).
        /// - parameter decoder: The `Decoder` instance in charge of decoding the CSV data.
        /// - parameter rowIndex: The CSV row targeted for decoding.
        /// - parameter fieldIndex: The CSV field targeted for decoding.
        init(unsafeDecoder decoder: ShadowDecoder, rowIndex: Int, fieldIndex: Int) {
            self._decoder = decoder
            self._focus = .field(rowIndex, fieldIndex)
        }
        
        /// Creates a single value container only if the passed decoder's coding path is valid.
        ///
        /// This initializer only allows the creation of a container when the decoder's coding path:
        /// - is empty (implying a single value container wrapping the whole CSV file).
        /// - has a single coding key with an integer value (implying a container wrapping a CSV row).
        /// - has two coding keys representing a row and a field index (implying a container wrapping a single CSV field).
        /// - parameter decoder: The `Decoder` instance in charge of decoding the CSV data.
        /// - throws: `CSVError<CSVDecoder>` exclusively.
        init(decoder: ShadowDecoder) throws {
            switch decoder.codingPath.count {
            case 2:
                let key = (row: decoder.codingPath[0], field: decoder.codingPath[1])
                let r = try key.row.intValue ?> CSVDecoder.Error._invalidRowKey(forKey: key.row, codingPath: decoder.codingPath)
                let f = try decoder.source._withUnsafeGuaranteedRef { try $0.fieldIndex(forKey: key.field, codingPath: decoder.codingPath) }
                    self._focus = .field(r, f)
            case 1:
                let key = decoder.codingPath[0]
                let r = try key.intValue ?> CSVDecoder.Error._invalidRowKey(forKey: key, codingPath: decoder.codingPath)
                self._focus = .row(r)
            case 0:
                self._focus = .file
            default:
                throw CSVDecoder.Error._invalidContainerRequest(codingPath: decoder.codingPath)
            }
            self._decoder = decoder
        }
        
        var codingPath: [CodingKey] {
            self._decoder.codingPath
        }
    }
}

extension ShadowDecoder.SingleValueContainer {
    func decode(_ type: String.Type) throws -> String {
        try self._lowlevelDecode { $0 }
    }
    
    func decodeNil() -> Bool {
        switch self._decoder.source._withUnsafeGuaranteedRef({ $0.configuration.nilStrategy }) {
        case .empty: return (try? self._lowlevelDecode { $0.isEmpty }) ?? false
        case .custom(let closure): return closure(self._decoder)
        }
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        switch self._decoder.source._withUnsafeGuaranteedRef({ $0.configuration.boolStrategy }) {
        case .deferredToBool:
            return try self._lowlevelDecode { Bool($0) }
        case .insensitive:
            return try self._lowlevelDecode {
                switch $0.uppercased() {
                case "TRUE", "YES": return true
                case "FALSE", "NO", "": return false
                default: return nil
                }
            }
        case .numeric:
            return try self._lowlevelDecode {
                switch $0 {
                case "1": return true
                case "0": return false
                default: return nil
                }
            }
        case .custom(let closure):
            return try closure(self._decoder)
        }
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        try self._lowlevelDecode { Int($0) }
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        try self._lowlevelDecode { Int8($0) }
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        try self._lowlevelDecode { Int16($0) }
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        try self._lowlevelDecode { Int32($0) }
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        try self._lowlevelDecode { Int64($0) }
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        try self._lowlevelDecode { UInt($0) }
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try self._lowlevelDecode { UInt8($0) }
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try self._lowlevelDecode { UInt16($0) }
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try self._lowlevelDecode { UInt32($0) }
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try self._lowlevelDecode { UInt64($0) }
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        try self._lowlevelDecode {
            guard let result = Float($0), result.isFinite else {
                switch self._decoder.source._withUnsafeGuaranteedRef({ $0.configuration.nonConformingFloatStrategy }) {
                case .throw: return nil
                case .convert(let positiveInfinity, let negativeInfinity, let nan):
                    switch $0 {
                    case positiveInfinity: return .infinity
                    case negativeInfinity: return -.infinity
                    case nan: return .nan
                    default: return nil
                    }
                }
            }
            
            return result
        }
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        try self._lowlevelDecode {
            guard let result = Double($0), result.isFinite else {
                switch self._decoder.source._withUnsafeGuaranteedRef({ $0.configuration.nonConformingFloatStrategy }) {
                case .throw: return nil
                case .convert(let positiveInfinity, let negativeInfinity, let nan):
                    switch $0 {
                    case positiveInfinity: return .infinity
                    case negativeInfinity: return -.infinity
                    case nan: return .nan
                    default: return nil
                    }
                }
            }

            return result
        }
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T:Decodable {
        switch type {
        case is Date.Type:    return try self.decode(Date.self) as! T
        case is Data.Type:    return try self.decode(Data.self) as! T
        case is Decimal.Type: return try self.decode(Decimal.self) as! T
        case is URL.Type:     return try self.decode(URL.self) as! T
        default: return try T(from: self._decoder)
        }
    }
}

extension ShadowDecoder.SingleValueContainer {
    /// Decodes a single value of the given type.
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    func decode(_ type: Date.Type) throws -> Date {
        switch self._decoder.source._withUnsafeGuaranteedRef({ $0.configuration.dateStrategy }) {
        case .deferredToDate:
            return try Date(from: self._decoder)
        case .secondsSince1970:
            let number = try self.decode(Double.self)
            return Foundation.Date(timeIntervalSince1970: number)
        case .millisecondsSince1970:
            let number = try self.decode(Double.self)
            return Foundation.Date(timeIntervalSince1970: number / 1_000)
        case .iso8601:
            let string = try self.decode(String.self)
            return try DateFormatter.iso8601.date(from: string) ?> CSVDecoder.Error._invalidDateISO(string: string, codingPath: self.codingPath)
        case .formatted(let formatter):
            let string = try self.decode(String.self)
            return try formatter.date(from: string) ?> CSVDecoder.Error._invalidDateFormatted(string: string, codingPath: self.codingPath)
        case .custom(let closure):
            return try closure(self._decoder)
        }
    }
    
    /// Decodes a single value of the given type.
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    func decode(_ type: Data.Type) throws -> Data {
        switch self._decoder.source._withUnsafeGuaranteedRef({ $0.configuration.dataStrategy }) {
        case .deferredToData:
            return try Data(from: self._decoder)
        case .base64:
            let string = try self.decode(String.self)
            return try Data(base64Encoded: string) ?> CSVDecoder.Error._invalidData64(string: string, codingPath: self.codingPath)
        case .custom(let closure):
            return try closure(self._decoder)
        }
    }
    
    /// Decodes a single value of the given type.
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    func decode(_ type: Decimal.Type) throws -> Decimal {
        switch self._decoder.source._withUnsafeGuaranteedRef({ $0.configuration.decimalStrategy }) {
        case .locale(let locale):
            let string = try self.decode(String.self)
            return try Decimal(string: string, locale: locale) ?> CSVDecoder.Error._invalidDecimal(string: string, locale: locale, codingPath: self.codingPath)
        case .custom(let closure):
            return try closure(self._decoder)
        }
    }
    
    /// Decodes a single value of the given type.
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    func decode(_ type: URL.Type) throws -> URL {
        try self._lowlevelDecode { URL(string: $0) }
    }
}

// MARK: -

private extension ShadowDecoder.SingleValueContainer {
    /// CSV keyed container focus (i.e. where the container is able to operate on).
    enum _Focus {
        /// The container represents the whole CSV file and each decoding operation outputs a row/record.
        case file
        /// The container represents a CSV row and each decoding operation outputs a field.
        case row(Int)
        /// The container represents a CSV field and there can only be a decoding operation output.
        case field(Int,Int)
    }
    
    /// Decodes the `String` value under the receiving single value container's `focus` and then tries to transform it in the requested type.
    /// - parameter transform: Closure transforming the decoded `String` value into the required type. If it fails, the closure returns `nil`.
    func _lowlevelDecode<T>(transform: (String) -> T?) throws -> T {
        try self._decoder.source._withUnsafeGuaranteedRef {
            switch self._focus {
            case .field(let rowIndex, let fieldIndex):
                let string = try $0.field(rowIndex, fieldIndex)
                return try transform(string) ?> CSVDecoder.Error._invalid(type: T.self, string: string, codingPath: self.codingPath)
            case .row(let rowIndex):
                // Values are only allowed to be decoded directly from a single value container in "row level" if the CSV has single column rows.
                guard $0.numExpectedFields == 1 else { throw CSVDecoder.Error._invalidNestedRequired(codingPath: self.codingPath) }
                let string = try $0.field(rowIndex, 0)
                return try transform(string) ?> CSVDecoder.Error._invalid(type: T.self, string: string, codingPath: self.codingPath + [IndexKey(0)])
            case .file:
                // Values are only allowed to be decoded directly from a single value container in "file level" if the CSV file has a single row with a single column.
                if try $0.isRowAtEnd(index: 1), $0.numExpectedFields == 1 {
                    let string = try $0.field(0, 0)
                    return try transform(string) ?> CSVDecoder.Error._invalid(type: T.self, string: string, codingPath: self.codingPath + [IndexKey(0), IndexKey(0)])
                } else {
                    throw CSVDecoder.Error._invalidNestedRequired(codingPath: self.codingPath)
                }
            }
        }
    }
}

fileprivate extension CSVDecoder.Error {
    /// Error raised when a coding key representing a row within the CSV file cannot be transformed into an integer value.
    /// - parameter codingPath: The whole coding path, including the invalid row key.
    static func _invalidRowKey(forKey key: CodingKey, codingPath: [CodingKey]) -> CSVError<CSVDecoder> {
        .init(.invalidPath,
              reason: "The coding key identifying a CSV row couldn't be transformed into an integer value.",
              help: "The provided coding key identifying a CSV row must implement `intValue`.",
              userInfo: ["Coding path": codingPath, "Key": key])
    }
    /// Error raised when a single value container is requested on an invalid coding path.
    /// - parameter codingPath: The full chain of containers which generated this error.
    static func _invalidContainerRequest(codingPath: [CodingKey]) -> CSVError<CSVDecoder> {
        .init(.invalidPath,
              reason: "A CSV doesn't support more than two nested decoding containers.",
              help: "Don't ask for a single value encoding container on this coding path.",
              userInfo: ["Coding path": codingPath])
    }
    /// Error raised when a value is decoded, but a container was expected by the decoder.
    static func _invalidNestedRequired(codingPath: [CodingKey]) -> CSVError<CSVDecoder> {
        .init(.invalidPath,
              reason: "A nested container is needed to decode CSV row values",
              help: "Request a nested container instead of trying to decode the value directly.",
              userInfo: ["Coding path": codingPath])
    }
    /// Error raised when transforming a `String` value into another type.
    /// - parameter value: The `String` value, which couldn't be transformed.
    /// - parameter codingPath: The full chain of containers when this error was generated.
    static func _invalid<T>(type: T.Type, string: String, codingPath: [CodingKey]) -> DecodingError {
        .typeMismatch(type, DecodingError.Context(
                      codingPath: codingPath,
                      debugDescription: "The field '\(string)' was not of the expected type '\(type)'."))
    }
    /// Error raised when a string value cannot be transformed into a `Date` using the ISO 8601 format.
    static func _invalidDateISO(string: String, codingPath: [CodingKey]) -> DecodingError {
        .dataCorrupted(DecodingError.Context(
                       codingPath: codingPath,
                       debugDescription: "The field '\(string)' couldn't be transformed into a Date using the '.iso8601' strategy."))
    }
    /// Error raised when a string value cannot be transformed into a `Date` using the ISO 8601 format.
    static func _invalidDateFormatted(string: String, codingPath: [CodingKey]) -> DecodingError {
        .dataCorrupted(DecodingError.Context(
                       codingPath: codingPath,
                       debugDescription: "The field '\(string)' couldn't be transformed into a Date using the '.formatted' strategy."))
    }
    /// Error raised when a string value cannot be transformed into a Base64 data blob.
    static func _invalidData64(string: String, codingPath: [CodingKey]) -> DecodingError {
        .dataCorrupted(DecodingError.Context(
                       codingPath: codingPath,
                       debugDescription: "The field '\(string)' couldn't be transformed into a Base64 data blob."))
    }
    /// Error raised when a string value cannot be transformed into a decimal number.
    static func _invalidDecimal(string: String, locale: Locale?, codingPath: [CodingKey]) -> DecodingError {
        var description = "The string '\(string)' couldn't be transformed into a Decimal using the '.locale' strategy."
        if let l = locale { description.append(" with locale '\(l)'") }
        return .dataCorrupted(DecodingError.Context(
                              codingPath: codingPath,
                              debugDescription: description))
    }
}
