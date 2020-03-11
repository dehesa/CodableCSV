extension Unicode.Scalar {
    /// Closure transforming a unicode scalar into bytes and passing the result to a `processor` function (in the form of a pointer).
    /// - throws: `CSVWriter.Error` exclusively.
    internal typealias Encoder = (_ scalar: Unicode.Scalar, _ processor: Processor) throws -> Void
    /// Closure receiving a given amount of bytes.
    /// - throws: `CSVWriter.Error` exclusively.
    internal typealias Processor = (_ buffer: UnsafePointer<UInt8>, _ length: Int) throws -> Void
}

extension String.Encoding {
    /// Returns a encoder to transform a Unicode scalar into the receiving encoding.
    /// - returns: An encoder if the transformation from Unicode scalar to the receiving encoding is supported or `nil` if it is not.
    internal var scalarEncoder: Unicode.Scalar.Encoder? {
        typealias E = String.Encoding
        
        switch self.rawValue {
        case E.ascii.rawValue:
            return E.scalarEncoderASCII()
        
        case E.utf8.rawValue:
            return E.scalarEncoderUTF8()
        
        case E.utf16.rawValue, E.unicode.rawValue:
            // You need to write the BOM at the beginning of the string, though
            return E.scalarEncoder(UTF16.self, endianness: .little)
        case E.utf16BigEndian.rawValue:
            return E.scalarEncoder(UTF16.self, endianness: .big)
        case E.utf16LittleEndian.rawValue:
            return E.scalarEncoder(UTF16.self, endianness: .little)
        
        case E.utf32.rawValue:
            // You need to write the BOM at the beginning of the string, though
            return E.scalarEncoder(UTF32.self, endianness: .little)
        case E.utf32BigEndian.rawValue:
            return E.scalarEncoder(UTF32.self, endianness: .big)
        case E.utf32LittleEndian.rawValue:
            return E.scalarEncoder(UTF32.self, endianness: .little)
        
        default:
            return nil
        }
    }
    
    /// Encoder from unicode scalar to ASCII.
    /// - throws: `CSVWriter.Error.invalidCommand` exclusively.
    private static func scalarEncoderASCII() -> Unicode.Scalar.Encoder {
        return { (scalar, processor) in
            guard let codeUnit = Unicode.ASCII.encode(scalar)?.first else {
                throw CSVWriter.Error.invalidCommand(#"Non-ASCII characters "\#(scalar)" have been encountered or only ASCII was expected"#)
            }
            
            try withUnsafePointer(to: codeUnit) { (codeUnit) in
                try processor(codeUnit, 1)
            }
        }
    }
    
    /// Encoder for unicode scalar to UTF8 code units.
    private static func scalarEncoderUTF8() -> Unicode.Scalar.Encoder {
        return { (scalar, processor) in
            var buffer: [Unicode.UTF8.CodeUnit] = .init()
            Unicode.UTF8.encode(scalar) { (codeUnit) in
                buffer.append(codeUnit)
            }
            try processor(buffer, buffer.count)
        }
    }
    
    /// Encoder for unicode scalar to UTF16 code units.
    private static func scalarEncoder<C:UnicodeCodec>(_ type: C.Type, endianness: Endianness) -> Unicode.Scalar.Encoder {
        return { (scalar, processor) in
            var buffer: [C.CodeUnit] = .init()
            C.encode(scalar) { (codeUnit) in
                let value = (endianness == .little) ? codeUnit.littleEndian : codeUnit.bigEndian
                buffer.append(value)
            }
            
            try buffer.withUnsafeBytes { (ptr) in
                try processor(ptr.baseAddress!.assumingMemoryBound(to: UInt8.self), ptr.count)
            }
        }
    }
}
