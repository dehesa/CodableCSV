import Foundation

extension Unicode.Scalar {
    ///
    internal typealias Encoder = (Unicode.Scalar, Storage) throws -> Void
    ///
    internal typealias Storage = (_ buffer: UnsafePointer<UInt8>, _ length: Int) throws -> Void
}

extension String.Encoding {
    ///
    internal var scalarEncoder: Unicode.Scalar.Encoder? {
        typealias E = String.Encoding
        
        switch self.rawValue {
        case E.utf8.rawValue:
            return { (scalar, storage) in
                var buffer: [Unicode.UTF8.CodeUnit] = .init()
                Unicode.UTF8.encode(scalar) { (codeUnit) in
                    buffer.append(codeUnit)
                }
                try storage(buffer, buffer.count)
            }
        case E.utf16.rawValue:
            return nil
        case E.utf16BigEndian.rawValue:
            return nil
        case E.utf16LittleEndian.rawValue:
            return nil
        case E.utf32.rawValue:
            return nil
        case E.utf32BigEndian.rawValue:
            return nil
        case E.utf32LittleEndian.rawValue:
            return nil
        case E.ascii.rawValue:
            return nil
        default:
            return nil
        }
    }
}

//public static let utf8 = Encoding(rawValue: 4)
//public static let utf16 = Encoding.unicode
//public static let utf16BigEndian = Encoding(rawValue: 0x90000100)
//public static let utf16LittleEndian = Encoding(rawValue: 0x94000100)
//public static let utf32 = Encoding(rawValue: 0x8c000100)
//public static let utf32BigEndian = Encoding(rawValue: 0x98000100)
//public static let utf32LittleEndian = Encoding(rawValue: 0x9c000100)
//public static let unicode = Encoding(rawValue: 10)
//public static let ascii = Encoding(rawValue: 1)

//public static let nextstep = Encoding(rawValue: 2)
//public static let japaneseEUC = Encoding(rawValue: 3)
//public static let isoLatin1 = Encoding(rawValue: 5)
//public static let symbol = Encoding(rawValue: 6)
//public static let nonLossyASCII = Encoding(rawValue: 7)
//public static let shiftJIS = Encoding(rawValue: 8)
//public static let isoLatin2 = Encoding(rawValue: 9)
//public static let windowsCP1251 = Encoding(rawValue: 11)
//public static let windowsCP1252 = Encoding(rawValue: 12)
//public static let windowsCP1253 = Encoding(rawValue: 13)
//public static let windowsCP1254 = Encoding(rawValue: 14)
//public static let windowsCP1250 = Encoding(rawValue: 15)
//public static let iso2022JP = Encoding(rawValue: 21)
//public static let macOSRoman = Encoding(rawValue: 30)
