import XCTest
@testable import CodableCSV

/// Tests generic and edge cases from a CSV writer perspective.
final class CSVWriterTests: XCTestCase {
    /// List of all tests to run through SPM.
    static let allTests = [
        ("testRegularUTF8", testRegularUTF8),
        ("testRegularUTF16", testRegularUTF16),
        ("testWriterData", testWriterData),
        ("testManualMemoryWriting", testManualMemoryWriting)
    ]
        
    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension CSVWriterTests {
    /// Tests a small CSV with UTF8 encoding.
    ///
    /// All delimiters (both field and row delimiters) will be used.
    func testRegularUTF8() throws {
        let input = [TestData.headers] + TestData.content
        let encodingCount = BOM.UTF8.count
        
        for rowDel in [.lineFeed, .carriageReturn, .carriageReturnLineFeed, .string("**\n**")] as [Delimiter.Row] {
            let rowDelCount = rowDel.stringValue!.utf8.count
            
            for fieldDel in [.comma, .semicolon, .tab, .string("-*-*-")] as [Delimiter.Field] {
                let fieldDelCount = fieldDel.stringValue!.utf8.count
                
                let config = EncoderConfiguration(fieldDelimiter: fieldDel, rowDelimiter: rowDel, headers: nil)
                
                let data = try CSVWriter.data(rows: input, encoding: .utf8, configuration: config)
                let total = encodingCount + input.reduce(0) { $0 + $1.reduce(0) { $0 + $1.utf8.count + fieldDelCount } + rowDelCount - fieldDelCount }
                XCTAssertGreaterThanOrEqual(data.count, total)
            }
        }
    }
    
    /// Tests a small CSV with UTF16 encodings.
    ///
    /// All delimiters (both field and row delimiters) will be used.
    func testRegularUTF16() throws {
        let input = [TestData.headers] + TestData.content
        
        for encoding in [.utf16, .utf16LittleEndian, .utf16BigEndian] as [String.Encoding] {
            let encodingCount = encoding.bom!.count / 2
            
            for rowDel in [.lineFeed, .carriageReturn, .carriageReturnLineFeed, .string("**\n**")] as [Delimiter.Row] {
                let rowDelCount = rowDel.stringValue!.utf16.count
                
                for fieldDel in [.comma, .semicolon, .tab, .string("-*-*-")] as [Delimiter.Field] {
                    let fieldDelCount = fieldDel.stringValue!.utf16.count
                    
                    let config = EncoderConfiguration(fieldDelimiter: fieldDel, rowDelimiter: rowDel, headers: nil)
                    
                    let data = try CSVWriter.data(rows: input, encoding: encoding, configuration: config)
                    let total = encodingCount + input.reduce(0) { $0 + $1.reduce(0) { $0 + $1.utf16.count + fieldDelCount } + rowDelCount - fieldDelCount }
                    XCTAssertGreaterThanOrEqual(data.count, total*2)
                }
            }
        }
    }

    /// Tests several ways to initialize the active writer.
    func testWriterData() throws {
        XCTAssertNoThrow(
            try CSVWriter.data(rows: TestData.content)
        )
        XCTAssertNoThrow(
            try CSVWriter.data(rows: TestData.content, configuration: .init(headers: TestData.headers))
        )
        XCTAssertNoThrow(
            try CSVWriter.data(rows: TestData.contentEdgeCases, configuration: .init(headers: TestData.headers))
        )
    }
    
    /// Tests the manual usages of `CSVWriter`.
    func testManualMemoryWriting() throws {
        guard var testData = ([TestData.headers] + TestData.content).toCSV() as Data? else { return XCTFail() }
        testData.insertBOM(encoding: .utf8)
        
        let writer = try CSVWriter(url: nil, encoding: .utf8, configuration: .init(headers: TestData.headers))
        for row in TestData.content.dropLast() {
            try writer.write(row: row)
        }
        
        let row = TestData.content.last!
        try writer.beginRow()
        try writer.write(field: row[0])
        try writer.write(fields: row.dropFirst())
        try writer.endRow()
        
        try writer.endFile()
        guard let writerData = writer.dataInMemory else { return XCTFail() }
        XCTAssertEqual(testData, writerData)
    }
}
