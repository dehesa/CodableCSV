import XCTest
@testable import CodableCSV

/// Tests generic and edge cases from a CSV writer perspective.
final class WriterTests: XCTestCase {
    /// List of all tests to run through SPM.
    static let allTests = [
        ("testRegularUTF8", testRegularUTF8),
        ("testRegularUTF16", testRegularUTF16),
        ("testWriterData", testWriterData),
        ("testManualMemoryWriting", testManualMemoryWriting),
        ("testFileCreation", testFileCreation),
        ("testOverwrite", testOverwrite),
        ("testEmptyRows", testEmptyRows),
        ("testUnkwnonEmptyRow", testUnkwnonEmptyRow)
    ]

    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension WriterTests {
    /// Tests a small CSV with UTF8 encoding.
    ///
    /// All delimiters (both field and row delimiters) will be used.
    func testRegularUTF8() throws {
        // The configuration values to be tested.
        let rowDelimiters: [Delimiter.Row] = ["\n", "\r", "\r\n", "**~**"]
        let fieldDelimiters: [Delimiter.Field] = [",", ";", "\t", "|", "||", "|-|"]
        let encodings: [String.Encoding] = [.utf8, .utf16LittleEndian, .utf16BigEndian, .utf16LittleEndian, .utf32BigEndian]
        // The data used for testing.
        let headers = TestData.headers
        let content = TestData.content
        
        // The actual testing implementation.
        let work: (_ configuration: CSVWriter.Configuration) throws -> Void = {
            let data = try CSVWriter.serialize(rows: content, into: Data.self, configuration: $0)
            guard let _ = String(data: data, encoding: $0.encoding!) else { return XCTFail() }
        }
        
        for r in rowDelimiters {
            for f in fieldDelimiters {
                let pair: Delimiter.Pair = (f, r)
                
                for encoding in encodings {
                    var c = CSVWriter.Configuration()
                    c.delimiters = pair
                    c.headers = headers
                    c.encoding = encoding
                    c.bomStrategy = .always
                    try work(c)
                }
            }
        }
        
//        let encodingCount = BOM.UTF8.count
//
//        for rowDel in [.lineFeed, .carriageReturn, .carriageReturnLineFeed, .custom("**\n**")] as [Delimiter.Row] {
//            let rowDelCount = rowDel.stringValue!.utf8.count
//
//            for fieldDel in [.comma, .semicolon, .tab, .custom("-*-*-")] as [Delimiter.Field] {
//                let fieldDelCount = fieldDel.stringValue!.utf8.count
//
//                let config = CSVWriter.Configuration(fieldDelimiter: fieldDel, rowDelimiter: rowDel)
//                let data = try CSVWriter.data(rows: input, encoding: .utf8, configuration: config)
//                let total = encodingCount + input.reduce(0) { $0 + $1.reduce(0) { $0 + $1.utf8.count + fieldDelCount } + rowDelCount - fieldDelCount }
//                XCTAssertGreaterThanOrEqual(data.count, total)
//            }
//        }
    }

    /// Tests a small CSV with UTF16 encodings.
    ///
    /// All delimiters (both field and row delimiters) will be used.
    func testRegularUTF16() throws {
//        let input = [TestData.headers] + TestData.content
//
//        for encoding in [.utf16, .utf16LittleEndian, .utf16BigEndian] as [String.Encoding] {
//            let encodingCount = encoding.bom!.count / 2
//
//            for rowDel in [.lineFeed, .carriageReturn, .carriageReturnLineFeed, .string("**\n**")] as [Delimiter.Row] {
//                let rowDelCount = rowDel.stringValue!.utf16.count
//
//                for fieldDel in [.comma, .semicolon, .tab, .string("-*-*-")] as [Delimiter.Field] {
//                    let fieldDelCount = fieldDel.stringValue!.utf16.count
//
//                    let config = CSVWriter.Configuration(fieldDelimiter: fieldDel, rowDelimiter: rowDel)
//                    let data = try CSVWriter.data(rows: input, encoding: encoding, configuration: config)
//                    let total = encodingCount + input.reduce(0) { $0 + $1.reduce(0) { $0 + $1.utf16.count + fieldDelCount } + rowDelCount - fieldDelCount }
//                    XCTAssertGreaterThanOrEqual(data.count, total*2)
//                }
//            }
//        }
    }

    /// Tests several ways to initialize the active writer.
    func testWriterData() throws {
//        XCTAssertNoThrow(
//            try CSVWriter.data(rows: TestData.content)
//        )
//        XCTAssertNoThrow(
//            try CSVWriter.data(rows: TestData.content, configuration: .init(headers: TestData.headers))
//        )
//        XCTAssertNoThrow(
//            try CSVWriter.data(rows: TestData.contentEdgeCases, configuration: .init(headers: TestData.headers))
//        )
    }

    /// Tests the manual usages of `CSVWriter`.
    func testManualMemoryWriting() throws {
//        guard var testData = ([TestData.headers] + TestData.content).toCSV() as Data? else { return XCTFail() }
//        testData.insertBOM(encoding: .utf8)
//
//        let writer = try CSVWriter(url: nil, encoding: .utf8, configuration: .init(headers: TestData.headers))
//        for row in TestData.content.dropLast() {
//            try writer.write(row: row)
//        }
//
//        let row = TestData.content.last!
//        try writer.write(field: row[0])
//        try writer.write(fields: row.dropFirst())
//        try writer.endRow()
//
//        try writer.endFile()
//        guard let writerData = writer.dataInMemory else { return XCTFail() }
//        XCTAssertEqual(testData, writerData)
    }

    /// Tests the file creation capabilities of `CSVWriter`.
    func testFileCreation() throws {
//        let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
//        let fileURL = directoryURL.appendingPathComponent(UUID().uuidString)
//        let writer = try CSVWriter(url: fileURL)
//        try writer.write(row: ["one", "two", "three"])
//        try writer.write(fields: ["four", "five", "six"])
//        try writer.endRow()
//        try writer.endFile()
    }

    /// Tests writing more fields that the ones being expected.
    func testOverwrite() throws {
//        let writer = try CSVWriter(url: nil)
//        try writer.write(row: ["one", "two", "three"])
//        do {
//            try writer.write(fields: ["four", "five", "six", "seven"])
//            XCTFail("The previous line shall throw an error")
//        } catch {
//            try writer.endFile()
//        }
    }

    /// Tests writing empty rows.
    func testEmptyRows() throws {
//        let writer = try CSVWriter(url: nil, configuration: .init(headers: ["One", "Two", "Three"]))
//        try writer.writeEmptyRow()
//        try writer.write(row: ["four", "five", "six"])
//        try writer.writeEmptyRow()
//        try writer.endFile()
    }

    /// Tests writing empty rows when the number of fields are unknown.
    func testUnkwnonEmptyRow() throws {
//        let writer = try CSVWriter(url: nil)
//        do {
//            try writer.writeEmptyRow()
//            XCTFail("The previous line shall throw an error")
//        } catch {
//            try writer.endFile()
//        }
    }
}
