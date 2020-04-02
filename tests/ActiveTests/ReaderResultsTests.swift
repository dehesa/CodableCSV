import XCTest
import CodableCSV

/// Tests generic and edge cases from a CSV reader perspective.
final class ReaderResultsTests: XCTestCase {
    override func setUp() {
        self.continueAfterFailure = false
    }
}

// MARK: -

extension ReaderResultsTests {
    /// The test data used for this file.
    private enum TestData {
        /// A CSV row representing a header row (4 fields).
        static let headers   =  ["seq", "Name", "Country", "Number Pair"]
        /// Small amount of regular CSV rows (4 fields per row).
        static let content  =  [["1", "Marcos", "Spain", "99"],
                                ["2", "Marine-Anaïs", "France", "88"],
                                ["3", "Alex", "Germany", "77"],
                                ["4", "Pei", "China", "66"],
                                ["5", "Idan", "Israel", "55"],
                                ["6", "Frankie", "Namibia", "44"],
                                ["7", "Kina", "Papua New Guinea", "33"]]
        /// Encodes the test data into a Swift `String`.
        /// - parameter sample:
        /// - parameter delimiters: Unicode scalars to use to mark fields and rows.
        /// - returns: Swift String representing the CSV file.
        static func toCSV(_ sample: [[String]], delimiters: Delimiter.Pair) -> String {
            let (f, r) = (String(delimiters.field.rawValue), String(delimiters.row.rawValue))
            return sample.map { $0.joined(separator: f) }.joined(separator: r).appending(r)
        }
    }
    
    private typealias Encoded = (string: String, data: Data)
}

// MARK: -

extension ReaderResultsTests {
    /// Tests the `Record` structure regular usage (i.e. subscripts, collection syntax, lookups, etc.).
    func testRecords() throws {
        // The configuration values to be tested.
        let delimiters: Delimiter.Pair = (field: ",", row: "\n")
        let headerStrategy: Strategy.Header = .firstLine
        // The data used for testing.
        let (headers, content) = (TestData.headers, TestData.content)
        let sample = TestData.toCSV([headers] + content, delimiters: delimiters)
        
        let reader = try CSVReader(input: sample) {
            $0.delimiters = delimiters
            $0.headerStrategy = headerStrategy
        }
        
        var (result, rowIndex) = ([CSVReader.Record](), 0)
        while let record = try reader.readRecord() {
            result.append(record)
            XCTAssertEqual(record.count, headers.count)
            XCTAssertEqual(content[rowIndex], record.row)
            XCTAssertTrue(record == content[rowIndex])
            
            for (fieldIndex, header) in headers.enumerated() {
                XCTAssertEqual(content[rowIndex][fieldIndex], record[header])
            }
            
            for (fieldIndex, field) in record.enumerated() {
                XCTAssertEqual(content[rowIndex][fieldIndex], field)
            }
            rowIndex += 1
        }
    }
    
    /// Tests the `FileView` structure regular usage.
    func testFileView() throws {
        // The configuration values to be tested.
        let delimiters: Delimiter.Pair = (field: ",", row: "\n")
        let headerStrategy: Strategy.Header = .firstLine
        // The data used for testing.
        let (headers, content) = (TestData.headers, TestData.content)
        let sample = TestData.toCSV([headers] + content, delimiters: delimiters)
        
        let file = try CSVReader.decode(input: sample) {
            $0.delimiters = delimiters
            $0.headerStrategy = headerStrategy
        }
        
        XCTAssertEqual(headers, file.headers)
        XCTAssertEqual(content, file.rows)
        
        for (rowIndex, row) in content.enumerated() {
            XCTAssertEqual(row, file[rowIndex])
            XCTAssertEqual(row, file.records[rowIndex].row)
            
            for (fieldIndex, field) in row.enumerated() {
                XCTAssertEqual(field, file[row: rowIndex, column: headers[fieldIndex]]!)
            }
        }
        
        for (columnIndex, columnName) in headers.enumerated() {
            XCTAssertEqual(file[column: columnIndex], content.map { $0[columnIndex] })
            XCTAssertEqual(file[column: columnName]!, content.map { $0[columnIndex] })
        }
    }
}
