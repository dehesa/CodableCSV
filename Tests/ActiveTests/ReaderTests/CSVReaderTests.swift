import XCTest
@testable import CSV

/// Tests generic and edge cases from a CSV reader perspective.
final class CSVReaderTests: XCTestCase {
    /// List of all tests to run through SPM.
    static let allTests = [
        ("testGeneric", testGeneric),
        ("testInvalidFieldCount", testInvalidFieldCount)
    ]
    
    /// Tests a small generic CSV with no headers.
    func testGeneric() {
        let inputs = [
            (CSV.Configuration(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headerStrategy: .none), TestData.Arrays.genericNoHeader),
            (CSV.Configuration(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headerStrategy: .firstLine), TestData.Arrays.genericHeader)
        ]
        
        for (config, input) in inputs {
            let inputString: String = input.toCSV(delimiters: (config.delimiters.field, config.delimiters.row))
            let parsed: CSVReader.ParsingResult
            do {
                parsed = try CSVReader.parse(string: inputString, configuration: config)
            } catch let error {
                return XCTFail("\n\(error)")
            }
            
            switch config.strategies.header {
            case .none:
                XCTAssertNil(parsed.headers)
                XCTAssertEqual(input.count, parsed.rows.count)
                XCTAssertEqual(input, parsed.rows)
            case .firstLine:
                XCTAssertNotNil(parsed.headers)
                XCTAssertEqual(input.first!, parsed.headers!)
                
                var inputRows = input
                inputRows.removeFirst()
                XCTAssertEqual(inputRows.count, parsed.rows.count)
                XCTAssertEqual(inputRows, parsed.rows)
            case .unknown:
                XCTFail("No test for unknown header strategy.")
            }
        }
    }
    
    /// Tests a small generic CSV with headers.
    func testGenericHeaders() {
        let input = TestData.Arrays.genericHeader
        let inputString: String = input.toCSV(delimiters: (.comma, .lineFeed))
        
        let configuration = CSV.Configuration(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headerStrategy: .firstLine, trimStrategy: .none)
        let parsed: CSVReader.ParsingResult
        do {
            parsed = try CSVReader.parse(string: inputString, configuration: configuration)
        } catch let error {
            return XCTFail("\n\(error)")
        }
        
        
    }
    
    /// Tests an invalid CSV input, which should lead to an error throw.
    /// - note: This test data randomly generate invalid data every time is run.
    func testInvalidFieldCount() {
        let input = TestData.Arrays.genericNoHeader.removingRandomFields(count: 2)
        let inputString: String = input.toCSV()
        
        let configuration = CSV.Configuration(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headerStrategy: .none, trimStrategy: .none)
        
        do {
            let _ = try CSVReader.parse(string: inputString, configuration: configuration)
            XCTFail("\nThe CSVReader should have flagged the input as invalid.")
        } catch let error as CSVReader.Error {
            guard case .invalidInput(_) = error else {
                return XCTFail("\nUnexpected CSVReader.Error:\n\(error)")
            }
        } catch let error {
            XCTFail("\nOnly CSVReader.Error shall be thrown. Instead the following error was received:\n\(error)")
        }
    }
    
}
