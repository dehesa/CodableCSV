#if canImport(Darwin)
import Foundation
#endif

/// The endiannes of a bunch of bytes.
internal enum Endianness: Equatable {
    case big, little
    
    /// Returns the byte order of the host system.
    static var nativeOrder: Self {
        let isBigEndian: Bool
        #if canImport(Darwin)
        isBigEndian = Int(CFByteOrderGetCurrent()) == Int(CFByteOrderBigEndian.rawValue)
        #else
        let number: UInt32 = 0x12345678
        let converted = number.bigEndian
        isBigEndian = number == converted
        #endif
        
        switch isBigEndian {
        case true: return .big
        case false: return .little
        }
    }
}

extension String.Encoding {
    /// Returns the Byte Order Marker for the receiving encoding.
    ///
    /// Only Unicode encodings have BOMs.
    internal var bom: [UInt8]? {
        switch self.rawValue {
        case Self.utf8.rawValue:
            return BOM.UTF8
        case Self.utf16LittleEndian.rawValue, Self.utf16.rawValue, Self.unicode.rawValue:
            return BOM.UTF16.littleEndian
        case Self.utf16BigEndian.rawValue:
            return BOM.UTF16.bigEndian
        case Self.utf32LittleEndian.rawValue, Self.utf32.rawValue:
            return BOM.UTF32.littleEndian
        case Self.utf32BigEndian.rawValue:
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
