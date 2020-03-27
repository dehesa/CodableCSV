extension ShadowEncoder {
    ///
    struct SingleValueContainer {
        /// The representation of the encoding process point-in-time.
        private let encoder: ShadowEncoder
        /// The container's target (or level).
        private let focus: Focus
        
        /// Fast initializer that doesn't perform any checks on the coding path (assuming it is valid).
        /// - parameter encoder: The `Encoder` instance in charge of encoding CSV data.
        /// - parameter rowIndex: The CSV row targeted for encoding.
        /// - parameter fieldIndex: The CSV field targeted for encoding.
        init(unsafeEncoder encoder: ShadowEncoder, rowIndex: Int, fieldIndex: Int) {
            self.encoder = encoder
            self.focus = .field(rowIndex, fieldIndex)
        }
        
        /// Creates a single value container only if the passed encoder's coding path is valid.
        /// - parameter encoder: The `Encoder` instance in charge of encoding CSV data.
        init(encoder: ShadowEncoder) {
            fatalError()
        }
        
        var codingPath: [CodingKey] {
            self.encoder.codingPath
        }
    }
}

extension ShadowEncoder.SingleValueContainer: SingleValueEncodingContainer {
    mutating func encode(_ value: String) throws {
        try self.lowlevelEncoding { $0 }
    }
    
    mutating func encodeNil() throws {
        try self.lowlevelEncoding { String() }
    }
    
    mutating func encode(_ value: Bool) throws {
        try self.lowlevelEncoding { String(value) }
    }
    
    mutating func encode(_ value: Int) throws {
        try self.lowlevelEncoding { String(value) }
    }
    
    mutating func encode(_ value: Int8) throws {
        try self.lowlevelEncoding { String(value) }
    }
    
    mutating func encode(_ value: Int16) throws {
        try self.lowlevelEncoding { String(value) }
    }
    
    mutating func encode(_ value: Int32) throws {
        try self.lowlevelEncoding { String(value) }
    }
    
    mutating func encode(_ value: Int64) throws {
        try self.lowlevelEncoding { String(value) }
    }
    
    mutating func encode(_ value: UInt) throws {
        try self.lowlevelEncoding { String(value) }
    }
    
    mutating func encode(_ value: UInt8) throws {
        try self.lowlevelEncoding { String(value) }
    }
    
    mutating func encode(_ value: UInt16) throws {
        try self.lowlevelEncoding { String(value) }
    }
    
    mutating func encode(_ value: UInt32) throws {
        try self.lowlevelEncoding { String(value) }
    }
    
    mutating func encode(_ value: UInt64) throws {
        try self.lowlevelEncoding { String(value) }
    }
    
    mutating func encode(_ value: Float) throws {
        let strategy = self.encoder.sink.configuration.floatStrategy
        try self.lowlevelEncoding {
            switch strategy {
            case .throw:
                throw DecodingError.invalidFloatingPoint(value, codingPath: self.codingPath)
            case .convert(let positiveInfinity, let negativeInfinity, let nan):
                if value.isNaN {
                    return nan
                } else if value.isInfinite {
                    return (value < 0) ? negativeInfinity : positiveInfinity
                } else { fatalError() }
            }
        }
    }
    
    mutating func encode(_ value: Double) throws {
        let strategy = self.encoder.sink.configuration.floatStrategy
        try self.lowlevelEncoding {
            switch strategy {
            case .throw:
                throw DecodingError.invalidFloatingPoint(value, codingPath: self.codingPath)
            case .convert(let positiveInfinity, let negativeInfinity, let nan):
                if value.isNaN {
                    return nan
                } else if value.isInfinite {
                    return (value < 0) ? negativeInfinity : positiveInfinity
                } else { fatalError() }
            }
        }
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        fatalError()
    }
}

extension ShadowEncoder.SingleValueContainer {
    /// CSV keyed container focus (i.e. where the container is able to operate on).
    private enum Focus {
        /// The container represents the whole CSV file and each encoding operation outputs a row/record.
        case file
        /// The container represents a CSV row and each encoding operation writes a field.
        case row(Int)
        /// The container represents a CSV field and there can only be one encoding operation.
        case field(Int,Int)
    }
    
    /// Encodes a value by transforming it into a `String` through the closure and then passing it to the sink.
    private func lowlevelEncoding<T>(transform: (T) throws -> String) throws {
        fatalError()
    }
}

fileprivate extension DecodingError {
    /// Error raised when a non-conformant floating-point is being encoded and there is no support.
    static func invalidFloatingPoint<T>(_ value: T, codingPath: [CodingKey]) -> DecodingError where T:BinaryFloatingPoint {
        DecodingError.dataCorrupted(
            Context(codingPath: codingPath,
                    debugDescription: "The value '\(value)' is a non-conformant floating-point.")
        )
    }
}
