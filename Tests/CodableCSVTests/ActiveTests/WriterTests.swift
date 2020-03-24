import XCTest
import CodableCSV

/// Tests generic and edge cases from a CSV writer perspective.
final class WriterTests: XCTestCase {
    /// List of all tests to run through SPM.
    static let allTests = [
        ("testEmpty", testEmpty),
        ("testRegularUsage", testRegularUsage),
        ("testManualMemoryWriting", testManualMemoryWriting),
        ("testFileCreation", testFileCreation),
        ("testFieldsOverflow", testFieldsOverflow),
        ("testEmptyRows", testEmptyRows),
        ("testUnkwnonEmptyRow", testUnkwnonEmptyRow)
    ]

    override func setUp() {
        self.continueAfterFailure = false
    }
}

// MARK: -

extension WriterTests {
    /// The test data used for this file.
    private enum TestData {
        /// A CSV row representing a header row (4 fields).
        static let headers = ["seq", "Name", "Country", "Number Pair"]
        /// Small amount of regular CSV rows (4 fields per row).
        static let content = [["1", "Marcos", "Spain", "99"],
                              ["2", "Marine-Anaïs", "France", "88"],
                              ["3", "Alex", "Germany", "77"],
                              ["4", "Pei", "China", "66"]]
        /// Encodes the test data into a Swift `String`.
        /// - parameter sample:
        /// - parameter delimiters: Unicode scalars to use to mark fields and rows.
        /// - returns: Swift String representing the CSV file.
        static func toCSV(_ sample: [[String]], delimiters: Delimiter.Pair) -> String {
            let (f, r) = (String(delimiters.field.rawValue), String(delimiters.row.rawValue))
            return sample.map { $0.joined(separator: f) }.joined(separator: r).appending(r)
        }
    }
}

// MARK: -

extension WriterTests {
    /// Test the correct encoding of an empty CSV (no headers, no content).
    func testEmpty() throws {
        let writer = try CSVWriter()
        try writer.endFile()
        let data = try writer.data()
        XCTAssertTrue(data.isEmpty)
    }
    
    /// Tests a small CSV with UTF8 encoding.
    ///
    /// All delimiters (both field and row delimiters) will be used.
    func testRegularUsage() throws {
        // The configuration values to be tested.
        let rowDelimiters: [Delimiter.Row] = ["\n", "\r", "\r\n", "**~**"]
        let fieldDelimiters: [Delimiter.Field] = [",", ";", "\t", "|", "||", "|-|"]
        let encodings: [String.Encoding] = [.utf8, .utf16LittleEndian, .utf16BigEndian, .utf16LittleEndian, .utf32BigEndian]
        // The data used for testing.
        let headers = TestData.headers
        let content = TestData.content
        let input = [TestData.headers] + TestData.content
        
        // The actual testing implementation.
        let work: (_ configuration: CSVWriter.Configuration, _ sample: String) throws -> Void = {
            let resultA = try CSVWriter.serialize(rows: content, into: String.self, configuration: $0)
            XCTAssertTrue(resultA == $1)
            let resultB = try CSVWriter.serialize(rows: content, configuration: $0)
            guard let stringB = String(data: resultB, encoding: $0.encoding!) else { return XCTFail("Unable to encode Data into String") }
            XCTAssertTrue(resultA == stringB)
        }
        
        for r in rowDelimiters {
            for f in fieldDelimiters {
                let pair: Delimiter.Pair = (f, r)
                let sample = TestData.toCSV(input, delimiters: pair)
                
                for encoding in encodings {
                    var c = CSVWriter.Configuration()
                    c.delimiters = pair
                    c.headers = headers
                    c.encoding = encoding
                    c.bomStrategy = .never
                    try work(c, sample)
                }
            }
        }
    }

    /// Tests the manual usages of `CSVWriter`.
    func testManualMemoryWriting() throws {
        // The data used for testing.
        let headers = TestData.headers
        let content = TestData.content
        let input = [TestData.headers] + TestData.content
        
        let writer = try CSVWriter { $0.headers = headers; $0.delimiters = (",", "\n"); $0.encoding = .utf8 }
        try content[0].forEach { try writer.write(field: $0) }
        try writer.endRow()
        
        try writer.write(fields: content[1])
        try writer.endRow()
        
        try writer.write(fields: content[2].dropLast())
        try writer.write(field: content[2].last!)
        try writer.endRow()
        
        for row in content[3...] {
            try writer.write(row: row)
        }
        
        try writer.endFile()
        
        let result = try writer.data()
        let data = TestData.toCSV(input, delimiters: (",", "\n")).data(using: .utf8)!
        XCTAssertTrue(result.elementsEqual(data))
    }

    /// Tests the file creation capabilities of `CSVWriter`.
    func testFileCreation() throws {
        let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent(UUID().uuidString)
        let writer = try CSVWriter(fileURL: fileURL, append: false)
        try writer.write(row: ["one", "two", "three"])
        try writer.write(fields: ["four", "five", "six"])
        try writer.endRow()
        try writer.endFile()
    }

    /// Tests writing more fields that the ones being expected.
    func testFieldsOverflow() throws {
        let writer = try CSVWriter()
        try writer.write(row: ["one", "two", "three"])
        do {
            try writer.write(fields: ["four", "five", "six", "seven"])
            XCTFail("The previous line shall throw an error")
        } catch {
            try writer.endFile()
        }
    }

    /// Tests writing empty rows.
    func testEmptyRows() throws {
        let writer = try CSVWriter { $0.headers = ["One", "Two", "Three"] }
        try writer.writeEmptyRow()
        try writer.write(row: ["four", "five", "six"])
        try writer.writeEmptyRow()
        try writer.endFile()
    }

    /// Tests writing empty rows when the number of fields are unknown.
    func testUnkwnonEmptyRow() throws {
        let writer = try CSVWriter()
        do {
            try writer.writeEmptyRow()
            XCTFail("The previous line shall throw an error")
        } catch {
            try writer.endFile()
        }
    }
}
