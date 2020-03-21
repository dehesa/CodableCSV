//extension Unicode.Scalar {
//    /// Closure transforming a unicode scalar into bytes and passing the result to a `processor` function (in the form of a pointer).
//    /// - throws: `CSVWriter.Error` exclusively.
//    internal typealias Encoder = (_ scalar: Unicode.Scalar, _ processor: Processor) throws -> Void
//    /// Closure receiving a given amount of bytes.
//    /// - throws: `CSVWriter.Error` exclusively.
//    internal typealias Processor = (_ buffer: UnsafePointer<UInt8>, _ length: Int) throws -> Void
//}
//
//extension String.Encoding {
//    /// Returns a encoder to transform a Unicode scalar into the receiving encoding.
//    /// - returns: An encoder if the transformation from Unicode scalar to the receiving encoding is supported or `nil` if it is not.
//    internal var scalarEncoder: Unicode.Scalar.Encoder? {
//        switch self.rawValue {
//        case Self.ascii.rawValue:
//            return { (scalar, processor) in
//                guard let codeUnit = Unicode.ASCII.encode(scalar)?.first else {
//                    throw CSVWriter.Error.invalidCommand(#"Non-ASCII characters "\#(scalar)" have been encountered or only ASCII values were expected"#)
//                }
//                
//                try withUnsafePointer(to: codeUnit) { (codeUnit) in
//                    try processor(codeUnit, 1)
//                }
//            }
//        case Self.utf8.rawValue:
//            return { (scalar, processor) in
//                var buffer: [Unicode.UTF8.CodeUnit] = .init()
//                Unicode.UTF8.encode(scalar) { (codeUnit) in
//                    buffer.append(codeUnit)
//                }
//                try processor(buffer, buffer.count)
//            }
//        // UTF16 & Unicode imply: follow the BOM and if it is not there, assume big endian.
//        case Self.utf16.rawValue, Self.unicode.rawValue, Self.utf16BigEndian.rawValue:
//            return Self.scalarToBigEndian(UTF16.self)
//        case Self.utf16LittleEndian.rawValue:
//            return Self.scalarToLittleEndian(UTF16.self)
//        // UTF32 implies: follow the BOM and if it is not there, assume big endian.
//        case Self.utf32.rawValue:
//            return Self.scalarToBigEndian(UTF32.self)
//        case Self.utf32BigEndian.rawValue:
//            return Self.scalarToBigEndian(UTF32.self)
//        case Self.utf32LittleEndian.rawValue:
//            return Self.scalarToLittleEndian(UTF32.self)
//        default: return nil
//        }
//    }
//}
//
//extension String.Encoding {
//    /// Encoder for unicode scalar to UTF16 code units.
//    private static func scalarToBigEndian<C:UnicodeCodec>(_ type: C.Type) -> Unicode.Scalar.Encoder {
//        return { (scalar, processor) in
//            var buffer: [C.CodeUnit] = .init()
//            C.encode(scalar) { buffer.append($0.bigEndian) }
//            
//            try buffer.withUnsafeBytes { (ptr) in
//                try processor(ptr.baseAddress!.assumingMemoryBound(to: UInt8.self), ptr.count)
//            }
//        }
//    }
//    
//    /// Encoder for unicode scalar to UTF16 code units.
//    private static func scalarToLittleEndian<C:UnicodeCodec>(_ type: C.Type) -> Unicode.Scalar.Encoder {
//        return { (scalar, processor) in
//            var buffer: [C.CodeUnit] = .init()
//            C.encode(scalar) { buffer.append($0.littleEndian) }
//            
//            try buffer.withUnsafeBytes { (ptr) in
//                try processor(ptr.baseAddress!.assumingMemoryBound(to: UInt8.self), ptr.count)
//            }
//        }
//    }
//}
