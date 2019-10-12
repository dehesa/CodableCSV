import XCTest
@testable import CodableCSV

/// Tests generic and edge cases from a CSV writer perspective.
final class CSVWriterTests: XCTestCase {
    /// List of all tests to run through SPM.
    static let allTests = [
        ("testGenericUTF8", testGenericUTF8),
        ("testGenericUTF16", testGenericUTF16)
    ]
    
    /// Tests a small generic CSV with UTF8 encoding.
    ///
    /// All delimiters (both field and row delimiters) will be used.
    func testGenericUTF8() {
        let input = TestData.Arrays.genericHeader
        let encodingCount = BOM.UTF8.count
        
        for rowDel in [.lineFeed, .carriageReturn, .carriageReturnLineFeed, .string("**\n**")] as [Delimiter.Row] {
            let rowDelCount = rowDel.stringValue!.utf8.count
            
            for fieldDel in [.comma, .semicolon, .tab, .string("-*-*-")] as [Delimiter.Field] {
                let fieldDelCount = fieldDel.stringValue!.utf8.count
                
                let config = EncoderConfiguration(fieldDelimiter: fieldDel, rowDelimiter: rowDel, headers: nil)
                
                do {
                    let data = try CSVWriter.data(rows: input, encoding: .utf8, configuration: config)
                    let total = encodingCount + input.reduce(0) { $0 + $1.reduce(0) { $0 + $1.utf8.count + fieldDelCount } + rowDelCount - fieldDelCount } 
                    XCTAssertGreaterThanOrEqual(data.count, total)
                } catch let error {
                    XCTFail("Unexpected error: \(error)")
                }
            }
        }
    }
    
    ///
    func testGenericUTF16() {
        let input = TestData.Arrays.genericHeader
        
        for encoding in [.utf16, .utf16LittleEndian, .utf16BigEndian] as [String.Encoding] {
            let encodingCount = encoding.bom!.count / 2
            
            for rowDel in [.lineFeed, .carriageReturn, .carriageReturnLineFeed, .string("**\n**")] as [Delimiter.Row] {
                let rowDelCount = rowDel.stringValue!.utf16.count
                
                for fieldDel in [.comma, .semicolon, .tab, .string("-*-*-")] as [Delimiter.Field] {
                    let fieldDelCount = fieldDel.stringValue!.utf16.count
                    
                    let config = EncoderConfiguration(fieldDelimiter: fieldDel, rowDelimiter: rowDel, headers: nil)
                    
                    do {
                        let data = try CSVWriter.data(rows: input, encoding: encoding, configuration: config)
                        
                        let total = encodingCount + input.reduce(0) { $0 + $1.reduce(0) { $0 + $1.utf16.count + fieldDelCount } + rowDelCount - fieldDelCount }
                        XCTAssertGreaterThanOrEqual(data.count, total*2)
                    } catch let error {
                        XCTFail("Unexpected error: \(error)")
                    }
                }
            }
        }
    }
}
