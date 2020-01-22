import XCTest
import CodableCSV

/// Tests generic and edge cases from a CSV reader perspective.
final class CSVReaderTests: XCTestCase {
    /// List of all tests to run through SPM.
    static let allTests = [
        ("testEmpty", testEmpty),
        ("testSingleValue", testSingleValue),
        ("testGeneric", testGeneric),
        ("testEdgeCases", testEdgeCases),
        ("testQuotedFields", testQuotedFields),
        ("testInvalidFieldCount", testInvalidFieldCount)
    ]
    
    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension CSVReaderTests {
    /// Tests the correct parsing of an empty CSV.
    func testEmpty() throws {
        let parsed = try CSVReader.parse(string: "", configuration: .init())
        XCTAssertNil(parsed.headers)
        XCTAssertTrue(parsed.rows.isEmpty)
    }
    
    /// Tests the correct parsing of a single value CSV.
    func testSingleValue() throws {
        let input = [["Marine-Anaïs"]]
        let config = DecoderConfiguration(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headerStrategy: .none)
        let parsed = try CSVReader.parse(string: input.toCSV(delimiters: config.delimiters), configuration: config)
        XCTAssertNil(parsed.headers)
        XCTAssertEqual(parsed.rows, input)
    }
    
    /// Tests a small generic CSV (with and without headers).
    ///
    /// All default delimiters (both field and row delimiters) will be used.
    func testGeneric() throws {
        for rowDel in [.lineFeed, .carriageReturn, .carriageReturnLineFeed] as [Delimiter.Row] {
            for fieldDel in [.comma, .semicolon, .tab] as [Delimiter.Field] {
                let inputs: [(DecoderConfiguration, [[String]])] = [
                    (.init(fieldDelimiter: fieldDel, rowDelimiter: rowDel, headerStrategy: .none), TestData.content),
                    (.init(fieldDelimiter: fieldDel, rowDelimiter: rowDel, headerStrategy: .firstLine), [TestData.headers] + TestData.content)
                ]
                
                for (config, input) in inputs {
                    let parsed = try CSVReader.parse(string: input.toCSV(delimiters: config.delimiters), configuration: config)
                    
                    switch config.headerStrategy {
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
        }
    }
    
    /// Tests a set of edge cases data.
    ///
    /// Some edge cases are, for example, the last row's field is empty or a row delimiter within quotes.
    func testEdgeCases() throws {
        let input = TestData.contentEdgeCases
        
        for rowDel in [.lineFeed, .carriageReturn, .carriageReturnLineFeed] as [Delimiter.Row] {
            for fieldDel in [.comma, .semicolon, .tab] as [Delimiter.Field] {
                let config = DecoderConfiguration(fieldDelimiter: fieldDel, rowDelimiter: rowDel, headerStrategy: .none)
                let parsed = try CSVReader.parse(string: input.toCSV(delimiters: config.delimiters), configuration: config)
                
                XCTAssertNil(parsed.headers)
                for (rowIndex, parsedRow) in parsed.rows.enumerated() {
                    for (fieldIndex, parsedField) in parsedRow.enumerated() {
                        var inputField = input[rowIndex][fieldIndex]
                        if inputField.hasPrefix("\""), inputField.hasSuffix("\"") {
                            inputField.removeFirst()
                            inputField.removeLast()
                        }
                        XCTAssertEqual(parsedField, inputField)
                    }
                }
            }
        }
    }
    
    /// Tests a small generic CSV with some of its fields quoted.
    /// - note: This test will randomly generate quoted fields from an unquoted set of data.
    func testQuotedFields() throws {
        let input = [TestData.headers] + TestData.content
        let quotedInput = input.mappingRandomFields(count: 5) { [quote = Character("\"")] in
            guard !$0.hasPrefix(String(quote)) else { return $0 }
            
            var field = $0
            field.insert(quote, at: field.startIndex)
            field.append(quote)
            return field
        }
        
        for rowDel in [.lineFeed, .carriageReturn, .carriageReturnLineFeed] as [Delimiter.Row] {
            for fieldDel in [.comma, .semicolon, .tab] as [Delimiter.Field] {
                let config = DecoderConfiguration(fieldDelimiter: fieldDel, rowDelimiter: rowDel, headerStrategy: .firstLine)
                let parsed = try CSVReader.parse(string: quotedInput.toCSV(delimiters: config.delimiters), configuration: config)
                
                XCTAssertNotNil(parsed.headers)
                XCTAssertEqual(input.first!, parsed.headers!)
                
                var inputRows = input
                inputRows.removeFirst()
                XCTAssertEqual(inputRows.count, parsed.rows.count)
                XCTAssertEqual(inputRows, parsed.rows)
            }
        }
    }
    
    /// Tests an invalid CSV input, which should lead to an error being thrown.
    /// - note: This test randomly generates invalid data every time is run.
    func testInvalidFieldCount() {
        for rowDel in [.lineFeed, .carriageReturn, .carriageReturnLineFeed] as [Delimiter.Row] {
            for fieldDel in [.comma, .semicolon, .tab] as [Delimiter.Field] {
                let input = TestData.content.removingRandomFields(count: 2)
                let inputString: String = input.toCSV(delimiters: (fieldDel, rowDel))
                
                let config = DecoderConfiguration(fieldDelimiter: fieldDel, rowDelimiter: rowDel, headerStrategy: .none)
                
                do {
                    let _ = try CSVReader.parse(string: inputString, configuration: config)
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
    }
}
