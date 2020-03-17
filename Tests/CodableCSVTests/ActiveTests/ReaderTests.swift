import XCTest
import CodableCSV

/// Tests generic and edge cases from a CSV reader perspective.
final class CSVReaderTests: XCTestCase {
    /// List of all tests to run through SPM.
    static let allTests = [
        ("testEmpty", testEmpty),
        ("testSingleValue", testSingleValue),
        ("testRegularUsage", testRegularUsage),
        ("testEdgeCases", testEdgeCases),
        ("testQuotedFields", testQuotedFields),
        ("testInvalidFieldCount", testInvalidFieldCount)
    ]

    override func setUp() {
        self.continueAfterFailure = false
    }
    
    private typealias Encoded = (string: String, data: Data)
}

extension CSVReaderTests {
    /// Tests the correct parsing of an empty CSV.
    func testEmpty() throws {
        let parsed = try CSVReader.parse(string: "", configuration: .init())
        XCTAssertTrue(parsed.headers.isEmpty)
        XCTAssertTrue(parsed.rows.isEmpty)
    }

    /// Tests the correct parsing of a single value CSV.
    func testSingleValue() throws {
        let input = [["Marine-Anaïs"]]
        let parsed = try CSVReader.parse(string: input.toCSV()) { $0.headerStrategy = .none }
        XCTAssertTrue(parsed.headers.isEmpty)
        XCTAssertEqual(parsed.rows, input)
    }

    /// Tests a small generic CSV (with and without headers).
    func testRegularUsage() throws {
        // The configuration values to be tested.
        let rowDelimiters: [Delimiter.Row] = ["\n", "\r", "\r\n", "**~**"]
        let fieldDelimiters: [Delimiter.Field] = [",", ";", "\t", "|", "||", "|-|"]
        let headerStrategy: [Strategy.Header] = [.none, .firstLine, /*.unknown*/]
        let trimStrategy: [CharacterSet] = [.init(), .whitespaces]
        let presamples: [Bool] = [true, false]
        // The data used for testing.
        let headers = TestData.headers
        let content = TestData.content
        
        // The actual testing implementation.
        let work: (_ configuration: CSVReader.Configuration, _ encoded: Encoded) throws -> Void = {
            let resultA = try CSVReader.parse(string: $1.string, configuration: $0)
            let resultB = try CSVReader.parse(data: $1.data, configuration: $0)
            
            if $0.headerStrategy == .none {
                XCTAssertTrue(resultA.headers.isEmpty)
                XCTAssertTrue(resultB.headers.isEmpty)
                XCTAssertEqual(resultA.rows, content)
                XCTAssertEqual(resultB.rows, content)
            } else {
                XCTAssertFalse(resultA.headers.isEmpty)
                XCTAssertEqual(resultA.headers, resultB.headers)
                XCTAssertEqual(resultA.headers, headers)
                XCTAssertEqual(resultA.rows, content)
                XCTAssertEqual(resultB.rows, content)
            }
        }
        
        // Iterate through all configuration values.
        for r in rowDelimiters {
            for f in fieldDelimiters {
                let pair: Delimiter.Pair = (f, r)
                
                for h in headerStrategy {
                    let input: [[String]]
                    switch h {
                    case .none: input = content
                    case .firstLine: input = [headers] + content
                    case .unknown: return XCTFail("Testing header inference is not yet supported")
                    }
                    let encoded: Encoded = (input.toCSV(delimiters: pair), input.toCSV(delimiters: pair))
                    
                    for t in trimStrategy {
                        var toTrim = t
                        if f.rawValue.count == 1, t.contains(f.rawValue.first!) { toTrim.remove(f.rawValue.first!) }
                        if r.rawValue.count == 1, t.contains(r.rawValue.first!) { toTrim.remove(r.rawValue.first!) }
                        
                        for p in presamples {
                            var c = CSVReader.Configuration()
                            c.delimiters = pair
                            c.headerStrategy = h
                            c.trimStrategry = toTrim
                            c.presample = p
                            
                            XCTAssertNoThrow(try work(c, encoded))
                        }
                    }
                }
            }
        }
    }

    /// Tests a set of edge cases data.
    ///
    /// Some edge cases are, for example, the last row's field is empty or a row delimiter within quotes.
    func testEdgeCases() throws {
        // The configuration values to be tested.
        let rowDelimiters: [Delimiter.Row] = ["\n", "\r", "\r\n", "**~**"]
        let fieldDelimiters: [Delimiter.Field] = [",", ";", "\t", "|", "||", "|-|"]
        let headerStrategy: [Strategy.Header] = [.none, .firstLine, /*.unknown*/]
        let trimStrategy: [CharacterSet] = [.init(), /*.whitespaces*/] // The whitespaces remove the row or field delimiters.
        let presamples: [Bool] = [true, false]
        // The data used for testing.
        let headers = TestData.headers
        let content = TestData.contentEdgeCases
        let unescapedContent = TestData.contentUnescapedEdgeCases
        
        // The actual testing implementation.
        let work: (_ configuration: CSVReader.Configuration, _ encoded: Encoded) throws -> Void = {
            let resultA = try CSVReader.parse(string: $1.string, configuration: $0)
            let resultB = try CSVReader.parse(data: $1.data, configuration: $0)
            
            if $0.headerStrategy == .none {
                XCTAssertTrue(resultA.headers.isEmpty)
                XCTAssertTrue(resultB.headers.isEmpty)
                XCTAssertEqual(resultA.rows, unescapedContent, String(reflecting: $0))
                XCTAssertEqual(resultB.rows, unescapedContent, String(reflecting: $0))
            } else {
                XCTAssertFalse(resultA.headers.isEmpty)
                XCTAssertEqual(resultA.headers, resultB.headers)
                XCTAssertEqual(resultA.headers, headers)
                XCTAssertEqual(resultA.rows, unescapedContent, String(reflecting: $0))
                XCTAssertEqual(resultB.rows, unescapedContent, String(reflecting: $0))
            }
        }
        // Iterate through all configuration values.
        for r in rowDelimiters {
            for f in fieldDelimiters {
                let pair: Delimiter.Pair = (f, r)
                
                for h in headerStrategy {
                    let input: [[String]]
                    switch h {
                    case .none: input = content
                    case .firstLine: input = [headers] + content
                    case .unknown: return XCTFail("Testing header inference is not yet supported")
                    }
                    let encoded: Encoded = (input.toCSV(delimiters: pair), input.toCSV(delimiters: pair))
                    
                    for t in trimStrategy {
                        var toTrim = t
                        if f.rawValue.count == 1, t.contains(f.rawValue.first!) { toTrim.remove(f.rawValue.first!) }
                        if r.rawValue.count == 1, t.contains(r.rawValue.first!) { toTrim.remove(r.rawValue.first!) }
                        
                        for p in presamples {
                            var c = CSVReader.Configuration()
                            c.delimiters = pair
                            c.headerStrategy = h
                            c.trimStrategry = toTrim
                            c.presample = p
                            
                            try work(c, encoded)
                        }
                    }
                }
            }
        }
    }

    /// Tests a small generic CSV with some of its fields quoted.
    /// - note: This test will randomly generate quoted fields from an unquoted set of data.
    func testQuotedFields() throws {
        // The configuration values to be tested.
        let rowDelimiters: [Delimiter.Row] = ["\n", "\r", "\r\n", "**~**"]
        let fieldDelimiters: [Delimiter.Field] = [",", ";", "\t", "|", "||", "|-|"]
        let trimStrategy: [CharacterSet] = [.init(), .whitespaces]
        let presamples: [Bool] = [true, false]
        // The data used for testing.
        let headers = TestData.headers
        let content = TestData.content
        let input = ([headers] + content).mappingRandomFields(count: 5) { [quote = Character("\"")] in
            guard !$0.hasPrefix(String(quote)) else { return $0 }
            
            var field = $0
            field.insert(quote, at: field.startIndex)
            field.append(quote)
            return field
        }
        
        // The actual testing implementation.
        let work: (_ configuration: CSVReader.Configuration, _ encoded: Encoded) throws -> Void = {
            let resultA = try CSVReader.parse(string: $1.string, configuration: $0)
            let resultB = try CSVReader.parse(data: $1.data, configuration: $0)
            XCTAssertFalse(resultA.headers.isEmpty)
            XCTAssertEqual(resultA.headers, resultB.headers)
            XCTAssertEqual(resultA.headers, headers)
            XCTAssertEqual(resultA.rows, content)
            XCTAssertEqual(resultB.rows, content)
        }
        
        // Iterate through all configuration values.
        for r in rowDelimiters {
            for f in fieldDelimiters {
                let pair: Delimiter.Pair = (f, r)
                let encoded: Encoded = (input.toCSV(delimiters: pair), input.toCSV(delimiters: pair))
                
                for t in trimStrategy {
                    var toTrim = t
                    if f.rawValue.count == 1, t.contains(f.rawValue.first!) { toTrim.remove(f.rawValue.first!) }
                    if r.rawValue.count == 1, t.contains(r.rawValue.first!) { toTrim.remove(r.rawValue.first!) }
                    
                    for p in presamples {
                        var c = CSVReader.Configuration()
                        c.delimiters = pair
                        c.headerStrategy = .firstLine
                        c.trimStrategry = toTrim
                        c.presample = p
                        
                        XCTAssertNoThrow(try work(c, encoded))
                    }
                }
            }
        }
    }

    /// Tests an invalid CSV input, which should lead to an error being thrown.
    /// - note: This test randomly generates invalid data every time is run.
    func testInvalidFieldCount() {
        // The configuration values to be tested.
        let rowDelimiters: [Delimiter.Row] = ["\n", "\r", "\r\n"]
        let fieldDelimiters: [Delimiter.Field] = [",", ";", "\t"]
        let presamples: [Bool] = [true, false]
        // The data used for testing.
        let headers = TestData.headers
        let content = TestData.content
        let input = ([headers] + content).removingRandomFields(count: 2)
        // Iterate through all configuration values.
        for r in rowDelimiters {
            for f in fieldDelimiters {
                let pair: Delimiter.Pair = (f, r)
                let encoded: Encoded = (input.toCSV(delimiters: pair), input.toCSV(delimiters: pair))
                
                for p in presamples {
                    var c = CSVReader.Configuration()
                    c.delimiters = pair
                    c.headerStrategy = .firstLine
                    c.presample = p
                    XCTAssertThrowsError(try CSVReader.parse(string: encoded.string, configuration: c))
                    XCTAssertThrowsError(try CSVReader.parse(data: encoded.data, configuration: c))
                }
            }
        }
    }
}
