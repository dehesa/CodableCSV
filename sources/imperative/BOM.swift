/// The "Byte Order Mark" (BOM) is a Unicode character, U+FEFF, whose appearance as a magic number at the start of a text stream can signal several things to a program consuming the text:
/// - The byte order, or endianness of the text stream.
/// - The fact that the text stream's encoding is Unicode, to a high level of confidence.
/// - Which Unicode encoding the text stream is encoded as.
///
/// For more inforamtion check the [Wikipedia page on BOM](https://en.wikipedia.org/wiki/Byte_order_mark).
internal enum BOM {
    /// BOM representation for UTF-8
    ///
    /// The Unicode Standard permits the BOM, but it does not recommend its use. Byte order has no meaning in UTF-8, so its only use in UTF-8 is to signal at the start that the text stream is encoded in UTF-8, or that it was converted to UTF-8 from a stream that contained an optional BOM.
    static var UTF8: [UInt8] { [0xEF, 0xBB, 0xBF] }
    /// BOM representation for UTF-16.
    ///
    /// In UTF-16, a BOM may be placed as the first character of a file or character stream to indicate the endianness (byte order) of all the 16-bit code units of the file or stream. If an attempt is made to read this stream with the wrong endianness, the bytes will be swapped, thus delivering the character U+FFFE, which is defined by Unicode as a "non character" that should never appear in the text.
    enum UTF16 {
        /// If 16-bit units are represented in big-endian byte order, the BOM will appear in the sequence of bytes as 0xFE 0xFF
        ///
        /// This sequence isn't valid UTF-8, so their presence indicates that the file is not encoded in UTF-8.
        static var bigEndian: [UInt8] { [0xFE, 0xFF] }
        /// If the 16-bit units use little-endian order, the BOM will appear in the sequence of bytes as 0xFF 0xFE
        ///
        /// This sequence isn't valid UTF-8, so their presence indicates that the file is not encoded in UTF-8.
        static var littleEndian: [UInt8] { [0xFF, 0xFE] }
    }
    
    /// The BOM for little-endian UTF-32 is the same pattern as a little-endian UTF-16 BOM followed by a NUL character, an unusual example of the BOM being the same pattern in two different encodings. Programmers using the BOM to identify the encoding will have to decide whether UTF-32 or a NUL first character is more likely.
    enum UTF32 {
        static var bigEndian: [UInt8] { [0x00, 0x00, 0xFE, 0xFF] }
        static var littleEndian: [UInt8] { [0xFF, 0xFE, 0x00, 0x00] }
    }
}

internal extension BOM {
    /// Returns a dictionary with all the supporte Byte Order Markers.
    static var allCases: [String.Encoding:[UInt8]] {
        [.utf8: BOM.UTF8,
         .utf16BigEndian: BOM.UTF16.bigEndian, .utf16LittleEndian: BOM.UTF16.littleEndian,
         .utf32BigEndian: BOM.UTF32.bigEndian, .utf32LittleEndian: BOM.UTF32.littleEndian]
    }
}
