import Foundation

extension ShadowDecoder {
    /// Single value container for the CSV shadow decoder.
    struct SingleValueContainer: SingleValueDecodingContainer {
        /// The representation of the decoding process point-in-time.
        private let decoder: ShadowDecoder
        /// The container's target (or level).
        private let focus: Focus
        
        /// Fast initializer that doesn't perform any checks on the coding path (assuming it is valid).
        /// - parameter decoder: The `Decoder` instance in charge of decoding the CSV data.
        /// - parameter rowIndex: The CSV row targeted for decoding.
        /// - parameter fieldIndex: The CSV field targeted for decoding.
        init(unsafeDecoder decoder: ShadowDecoder, rowIndex: Int, fieldIndex: Int) {
            self.decoder = decoder
            self.focus = .field(rowIndex, fieldIndex)
        }
        
        /// Creates a single value container only if the passed decoder's coding path is valid.
        ///
        /// This initializer only allows the creation of a container when the decoder's coding path:
        /// - is empty (implying a single value container wrapping the whole CSV file).
        /// - has a single coding key with an integer value (implying a container wrapping a CSV row).
        /// - has two coding keys representing a row and a field index (implying a container wrapping a single CSV field).
        /// - parameter decoder: The `Decoder` instance in charge of decoding the CSV data.
        /// - throws: `DecodingError` exclusively.
        init(decoder: ShadowDecoder) throws {
            switch decoder.codingPath.count {
            case 2:
                let key = (row: decoder.codingPath[0], field: decoder.codingPath[1])
                let r = try key.row.intValue ?! DecodingError.invalidKey(forRow: key.row, codingPath: decoder.codingPath)
                let f = try decoder.source.fieldIndex(forKey: key.field, codingPath: decoder.codingPath)
                    self.focus = .field(r, f)
            case 1:
                let key = decoder.codingPath[0]
                let r = try key.intValue ?! DecodingError.invalidKey(forRow: key, codingPath: decoder.codingPath)
                self.focus = .row(r)
            case 0:
                self.focus = .file
            default:
                throw DecodingError.invalidContainerRequest(codingPath: decoder.codingPath)
            }
            self.decoder = decoder
        }
        
        var codingPath: [CodingKey] {
            self.decoder.codingPath
        }
    }
}

// MARK: -

extension ShadowDecoder.SingleValueContainer {
    func decode(_ type: String.Type) throws -> String {
        try self.lowlevelDecode { $0 }
    }
    
    func decodeNil() -> Bool {
        (try? self.lowlevelDecode { $0.isEmpty }) ?? false
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        try self.lowlevelDecode {
            switch $0.uppercased() {
            case "TRUE", "YES": return true
            case "FALSE", "NO", "": return false
            default: return nil
            }
        }
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        try self.lowlevelDecode { Int($0) }
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        try self.lowlevelDecode { Int8($0) }
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        try self.lowlevelDecode { Int16($0) }
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        try self.lowlevelDecode { Int32($0) }
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        try self.lowlevelDecode { Int64($0) }
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        try self.lowlevelDecode { UInt($0) }
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try self.lowlevelDecode { UInt8($0) }
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try self.lowlevelDecode { UInt16($0) }
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try self.lowlevelDecode { UInt32($0) }
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try self.lowlevelDecode { UInt64($0) }
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        let strategy = self.decoder.source.configuration.floatStrategy
        return try self.lowlevelDecode {
            if let result = Double($0) {
                return abs(result) <= Double(Float.greatestFiniteMagnitude) ? Float(result) : nil
            } else if case .convert(let positiveInfinity, let negativeInfinity, let nanSymbol) = strategy {
                switch $0 {
                case positiveInfinity: return  Float.infinity
                case negativeInfinity: return -Float.infinity
                case nanSymbol: return Float.nan
                default: break
                }
            }
            return nil
        }
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        let strategy = self.decoder.source.configuration.floatStrategy
        return try self.lowlevelDecode {
            if let result = Double($0) {
                return result
            } else if case .convert(let positiveInfinity, let negativeInfinity, let nanSymbol) = strategy {
                switch $0 {
                case positiveInfinity: return  Double.infinity
                case negativeInfinity: return -Double.infinity
                case nanSymbol: return Double.nan
                default: break
                }
            }
            return nil
        }
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T:Decodable {
        switch type {
        case is Date.Type:    return try self.decode(Date.self) as! T
        case is Data.Type:    return try self.decode(Data.self) as! T
        case is Decimal.Type: return try self.decode(Decimal.self) as! T
        case is URL.Type:     return try self.decode(URL.self) as! T
        default: return try T(from: self.decoder)
        }
    }
}

internal extension ShadowDecoder.SingleValueContainer {
    /// Decodes a single value of the given type.
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    func decode(_ type: Date.Type) throws -> Date {
        switch self.decoder.source.configuration.dateStrategy {
        case .deferredToDate:
            return try Date(from: self.decoder)
        case .secondsSince1970:
            let number = try self.decode(Double.self)
            return Foundation.Date(timeIntervalSince1970: number)
        case .millisecondsSince1970:
            let number = try self.decode(Double.self)
            return Foundation.Date(timeIntervalSince1970: number / 1_000)
        case .iso8601:
            let string = try self.decode(String.self)
            return try DateFormatter.iso8601.date(from: string) ?! DecodingError.invalidDateISO(string: string, codingPath: self.codingPath)
        case .formatted(let formatter):
            let string = try self.decode(String.self)
            return try formatter.date(from: string) ?! DecodingError.invalidDateFormatted(string: string, codingPath: self.codingPath)
        case .custom(let closure):
            return try closure(self.decoder)
        }
    }
    
    /// Decodes a single value of the given type.
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    func decode(_ type: Data.Type) throws -> Data {
        switch self.decoder.source.configuration.dataStrategy {
        case .deferredToData:
            return try Data(from: self.decoder)
        case .base64:
            let string = try self.decode(String.self)
            return try Data(base64Encoded: string) ?! DecodingError.invalidData64(string: string, codingPath: self.codingPath)
        case .custom(let closure):
            return try closure(self.decoder)
        }
    }
    
    /// Decodes a single value of the given type.
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    func decode(_ type: Decimal.Type) throws -> Decimal {
        switch self.decoder.source.configuration.decimalStrategy {
        case .locale(let locale):
            let string = try self.decode(String.self)
            return try Decimal(string: string, locale: locale) ?! DecodingError.invalidDecimal(string: string, locale: locale, codingPath: self.codingPath)
        case .custom(let closure):
            return try closure(self.decoder)
        }
    }
    
    /// Decodes a single value of the given type.
    /// - parameter type: The type to decode as.
    /// - returns: A value of the requested type.
    func decode(_ type: URL.Type) throws -> URL {
        try self.lowlevelDecode { URL(string: $0) }
    }
}

// MARK: -

private extension ShadowDecoder.SingleValueContainer {
    /// CSV keyed container focus (i.e. where the container is able to operate on).
    enum Focus {
        /// The container represents the whole CSV file and each decoding operation outputs a row/record.
        case file
        /// The container represents a CSV row and each decoding operation outputs a field.
        case row(Int)
        /// The container represents a CSV field and there can only be a decoding operation output.
        case field(Int,Int)
    }
    
    /// Decodes the `String` value under the receiving single value container's `focus` and then tries to transform it in the requested type.
    /// - parameter transform: Closure transforming the decoded `String` value into the required type. If it fails, the closure returns `nil`.
    func lowlevelDecode<T>(transform: (String) -> T?) throws -> T {
        let source = self.decoder.source
        
        switch self.focus {
        case .field(let rowIndex, let fieldIndex):
            let string = try source.field(rowIndex, fieldIndex)
            return try transform(string) ?! DecodingError.invalid(type: T.self, string: string, codingPath: self.codingPath)
        case .row(let rowIndex):
            // Values are only allowed to be decoded directly from a single value container in "row level" if the CSV has single column rows.
            guard source.numExpectedFields == 1 else { throw DecodingError.invalidNestedRequired(codingPath: self.codingPath) }
            let string = try source.field(rowIndex, 0)
            return try transform(string) ?! DecodingError.invalid(type: T.self, string: string, codingPath: self.codingPath + [IndexKey(0)])
        case .file:
            // Values are only allowed to be decoded directly from a single value container in "file level" if the CSV file has a single row with a single column.
            if source.isRowAtEnd(index: 1), source.numExpectedFields == 1 {
                let string = try self.decoder.source.field(0, 0)
                return try transform(string) ?! DecodingError.invalid(type: T.self, string: string, codingPath: self.codingPath + [IndexKey(0), IndexKey(0)])
            } else {
                throw DecodingError.invalidNestedRequired(codingPath: self.codingPath)
            }
        }
    }
}

fileprivate extension DecodingError {
    /// Error raised when a coding key representing a row within the CSV file cannot be transformed into an integer value.
    /// - parameter codingPath: The whole coding path, including the invalid row key.
    static func invalidKey(forRow key: CodingKey, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.keyNotFound(key, .init(
            codingPath: codingPath,
            debugDescription: "The coding key identifying a CSV row couldn't be transformed into an integer value."))
    }
    /// Error raised when a single value container is requested on an invalid coding path.
    /// - parameter codingPath: The full chain of containers which generated this error.
    static func invalidContainerRequest(codingPath: [CodingKey]) -> DecodingError {
        DecodingError.dataCorrupted(
            Context(codingPath: codingPath,
                    debugDescription: "CSV doesn't support more than two nested decoding container.")
        )
    }
    /// Error raised when a value is decoded, but a container was expected by the decoder.
    static func invalidNestedRequired(codingPath: [CodingKey]) -> DecodingError {
        DecodingError.dataCorrupted(.init(
            codingPath: codingPath,
            debugDescription: "A nested container is needed to decode CSV row values"))
    }
    /// Error raised when transforming a `String` value into another type.
    /// - parameter value: The `String` value, which couldn't be transformed.
    /// - parameter codingPath: The full chain of containers when this error was generated.
    static func invalid<T>(type: T.Type, string: String, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.typeMismatch(type,
            Context(codingPath: codingPath,
                    debugDescription: "The field '\(string)' was not of the expected type '\(type)'.")
        )
    }
    /// Error raised when a string value cannot be transformed into a `Date` using the ISO 8601 format.
    static func invalidDateISO(string: String, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.dataCorrupted(
            Context(codingPath: codingPath,
                    debugDescription: "The field '\(string)' couldn't be transformed into a Date using the '.iso8601' strategy.")
        )
    }
    /// Error raised when a string value cannot be transformed into a `Date` using the ISO 8601 format.
    static func invalidDateFormatted(string: String, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.dataCorrupted(
            Context(codingPath: codingPath,
                    debugDescription: "The field '\(string)' couldn't be transformed into a Date using the '.formatted' strategy.")
        )
    }
    /// Error raised when a string value cannot be transformed into a Base64 data blob.
    static func invalidData64(string: String, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.dataCorrupted(
            Context(codingPath: codingPath,
                    debugDescription: "The field '\(string)' couldn't be transformed into a Base64 data blob.")
        )
    }
    /// Error raised when a string value cannot be transformed into a decimal number.
    static func invalidDecimal(string: String, locale: Locale?, codingPath: [CodingKey]) -> DecodingError {
        var description = "The string '\(string)' couldn't be transformed into a Decimal using the '.locale' strategy."
        if let l = locale { description.append(" with locale '\(l)'") }
        return DecodingError.dataCorrupted(Context(codingPath: codingPath, debugDescription: description))
    }
}
