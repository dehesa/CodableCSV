import Foundation

extension Data {
    /// Tries to infer the String encoding from the data alone.
    func inferEncoding() -> String.Encoding? {
        // Look at the first 4 bytes and see if it is a BOM marker.
        if let encoding = self.byteOrderMarkEncoding {
            return encoding
        } else if self.isASCII {
            return .ascii
        } else if self.isUTF8 {
            return .utf8
        } else {
            return nil
        }
    }
    
    /// Reads the first bytes from a data blob and if it has a BOM (Byte Order Mark), it returns the String encoding.
    ///
    /// This algorithm may erroneously indicate that a data blob is `.utf32LittleEndian` when in reality is a `.utf16LittleEndian` if the first two bytes after the BOM are zeros.
    /// - returns: The String enconding if the BOM marker is found.
    /// - seealso: [How to guess the encoding of a document?](https://unicodebook.readthedocs.io/guess_encoding.html)
    private var byteOrderMarkEncoding: String.Encoding? {
        var buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 4)
        defer { buffer.deallocate() }
        
        let count = self.copyBytes(to: buffer)
        guard let ptr = buffer.baseAddress else { return nil }
        
        if count >= 3 {
            if memcmp(ptr, BOM.UTF8, 3) == 0 { return .utf8 }
        }
        
        if count >= 4 {
            if memcmp(ptr, BOM.UTF32.bigEndian, 4) == 0 { return .utf32BigEndian }
            if memcmp(ptr, BOM.UTF32.littleEndian, 4) == 0 { return .utf32LittleEndian }
        }
        
        if count >= 2 {
            if memcmp(ptr, BOM.UTF16.bigEndian, 2) == 0 { return .utf16BigEndian }
            if memcmp(ptr, BOM.UTF16.littleEndian, 2) == 0 { return .utf16LittleEndian }
        }
        
        return nil
    }
    
    /// Reads all bytes in the receiving data blob and if the bit 7 of all bytes is unset, then it is ASCII encoded.
    /// - returns: Boolean indicating whether all bytes are ASCII encoded.
    private var isASCII: Bool {
        let mask: UInt8 = 0x1 << 7
        for byte in self where byte & mask == 1 {
            return false
        }
        
        return true
    }
    
    /// Reads all bytes in the receiving data blob
    ///
    /// UTF-8 encoding adds markers to each bytes, so it is possible to write a reliable algorithm.
    /// - note: It rejects overlong sequences (e.g. `0xC0 0x80`) and surrogate characters (e.g. `0xED 0xB2 0x80`).
    /// - seealso: [Is UTF-8?](https://unicodebook.readthedocs.io/guess_encoding.html#is-utf-8)
    private var isUTF8: Bool {
        var locator = self.startIndex
        let end = self.endIndex

        while locator != end {
            let byte = self[locator]
            
            // Check if this is a single byte character. 1 byte sequence: U+0000..U+007F
            if byte <= 0x7F {
                locator = self.index(after: locator)
                continue
            }
            
            // Retrieve the length of the multibyte character.
            guard let length = MultibyteCharacter(firstByte: byte) else {
                return false
            }
            
            // Check if the blob contains the whole multibyte character.
            if self.index(locator, offsetBy: length.rawValue-1) >= end {
                return false
            }
            
            // Check continuation bytes: bit 7 should be set, bit 6 should be unset (b10xxxxxx).
            for offset in 0..<length.rawValue {
                let i = locator.advanced(by: offset)
                guard (self[i] & 0xC0) == 0x80 else { return false }
            }
            
            switch length {
            // 2 bytes sequence: U+0080..U+07FF
            case .two:
                // let ch = (UInt32(self[locator]                 & 0x1F) << 6) +
                //          UInt32(self[locator.advanced(by: 1)] & 0x3F)
                break
                // self[locator] >= 0xC2, so ch >= 0x0080.
                // self[locator] <= 0xDF, (self[locator+1] & 0x3F) <= 0x3F, so ch <= 0x07FF
            // 3 bytes sequence: U+0800..U+FFFF
            case .three:
                let ch = (UInt32(self[locator]                 & 0x0F) << 12) +
                         (UInt32(self[locator.advanced(by: 1)] & 0x3F) <<  6) +
                          UInt32(self[locator.advanced(by: 2)] & 0x3F)
                // (0xFF & 0x0F) << 12 | (0xFF & 0x3F) << 6 | (0xFF & 0x3F) = 0xFFFF, so ch <= 0xFFFF
                guard ch >= 0x0800 else { return false }
                // Surrogates (U+D800-U+DFFF) are invalid in UTF-8
                if (ch >> 11) == 0x1B { return false }
            // 4 bytes sequence: U+10000..U+10FFFF
            case .four:
                let ch = (UInt32(self[locator]                 & 0x07) << 18) +
                         (UInt32(self[locator.advanced(by: 1)] & 0x3F) << 12) +
                         (UInt32(self[locator.advanced(by: 2)] & 0x3F) <<  6) +
                          UInt32(self[locator.advanced(by: 3)] & 0x3F)
                if (ch < 0x10000) || (0x10FFFF < ch) { return false }
            }
            
            locator = self.index(locator, offsetBy: length.rawValue)
        }
    
        return true
    }
    
    private enum MultibyteCharacter: Int {
        case two = 2
        case three = 3
        case four = 4
        
        init?(firstByte byte: UInt8) {
            switch byte {
            case 0xC2...0xDF: self = .two   // 0b110xxxxx: 2 bytes sequence
            case 0xE0...0xEF: self = .three // 0b1110xxxx: 3 bytes sequence
            case 0xF0...0xF4: self = .four  // 0b11110xxx: 4 bytes sequence
            default: return nil             // Invalid first byte of a multibyte character
            }
        }
    }
}

/// The "Byte Order Mark" (BOM) is a Unicode character, U+FEFF, whose appearance as a magic number at the start of a text stream can signal several things to a program consuming the text:
/// - The byte order, or endianness of the text stream.
/// - The fact that the text stream's encoding is Unicode, to a high level of confidence.
/// - Which Unicode encoding the text stream is encoded as.
///
/// For more inforamtion check the [Wikipedia page on BOM](https://en.wikipedia.org/wiki/Byte_order_mark).
private enum BOM {
    /// BOM representation for UTF-8
    ///
    /// The Unicode Standard permits the BOM, but it does not recommend its use. Byte order has no meaning in UTF-8, so its only use in UTF-8 is to signal at the start that the text stream is encoded in UTF-8, or that it was converted to UTF-8 from a stream that contained an optional BOM.
    static let UTF8: [UInt8] = [0xEF, 0xBB, 0xBF]
    /// BOM representation for UTF-16.
    ///
    /// In UTF-16, a BOM may be placed as the first character of a file or character stream to indicate the endianness (byte order) of all the 16-bit code units of the file or stream. If an attempt is made to read this stream with the wrong endianness, the bytes will be swapped, thus delivering the character U+FFFE, which is defined by Unicode as a "non character" that should never appear in the text.
    enum UTF16 {
        /// If 16-bit units are represented in big-endian byte order, the BOM will appear in the sequence of bytes as 0xFE 0xFF
        ///
        /// This sequence isn't valid UTF-8, so their presence indicates that the file is not encoded in UTF-8.
        static let bigEndian: [UInt8] = [0xFE, 0xFF]
        /// If the 16-bit units use little-endian order, the BOM will appear in the sequence of bytes as 0xFF 0xFE
        ///
        /// This sequence isn't valid UTF-8, so their presence indicates that the file is not encoded in UTF-8.
        static let littleEndian: [UInt8] = [0xFF, 0xFE]
    }
    
    /// The BOM for little-endian UTF-32 is the same pattern as a little-endian UTF-16 BOM followed by a NUL character, an unusual example of the BOM being the same pattern in two different encodings. Programmers using the BOM to identify the encoding will have to decide whether UTF-32 or a NUL first character is more likely.
    enum UTF32 {
        static let bigEndian: [UInt8] = [0x00, 0x00, 0xFE, 0xFF]
        static let littleEndian: [UInt8] = [0xFF, 0xFE, 0x00, 0x00]
    }
}
