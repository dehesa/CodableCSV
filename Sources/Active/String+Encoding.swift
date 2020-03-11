extension String.Encoding {
    /// The endiannes of a bunch of bytes.
    internal enum Endianness: Equatable {
        case big, little
    }
    
    /// Returns the Byte Order Marker for the receiving encoding.
    ///
    /// Only Unicode encodings have BOMs.
    internal var bom: [UInt8]? {
        typealias E = String.Encoding
        
        switch self.rawValue {
        case E.utf8.rawValue:
            return BOM.UTF8
        case E.utf16LittleEndian.rawValue, E.utf16.rawValue, E.unicode.rawValue:
            return BOM.UTF16.littleEndian
        case E.utf16BigEndian.rawValue:
            return BOM.UTF16.bigEndian
        case E.utf32LittleEndian.rawValue, E.utf32.rawValue:
            return BOM.UTF32.littleEndian
        case E.utf32BigEndian.rawValue:
            return BOM.UTF32.bigEndian
        default:
            return nil
        }
    }
}

extension Unicode.Scalar {
    /// The quote unicode scalar used as escaping character.
    internal static let quote: Unicode.Scalar = "\""
}

/// Conforming instances return string or unicode scalar representations.
public protocol StringRepresentable {
    /// Returns a `String` representation of the receiving instance.
    var stringValue: String? { get }
}

extension StringRepresentable {
    /// Returns a `UnicodeScalarView` representation of the receiving instance.
    internal var unicodeScalars: String.UnicodeScalarView? {
        return self.stringValue?.unicodeScalars
    }
}
