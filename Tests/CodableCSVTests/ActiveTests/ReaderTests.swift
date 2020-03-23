import XCTest
import CodableCSV

/// Tests generic and edge cases from a CSV reader perspective.
final class ReaderTests: XCTestCase {
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
}

// MARK: -

extension ReaderTests {
    /// The test data used for this file.
    private enum TestData {
        /// A CSV row representing a header row (4 fields).
        static let headers   =  ["seq", "Name", "Country", "Number Pair"]
        /// Small amount of regular CSV rows (4 fields per row).
        static let content  =  [["1", "Marcos", "Spain", "99"],
                                ["2", "Marine-Anaïs", "France", "88"],
                                ["3", "Alex", "Germany", "77"],
                                ["4", "Pei", "China", "66"]]
        /// A bunch of rows each one containing an edge case.
        static let edgeCases = [["", "Marcos", "Spaiñ", "99"],
                                ["2", "Marine-Anaïs", #""Fra""nce""#, ""],
                                ["", "", "", ""],
                                ["4", "Pei", "China", #""\#n""#],
                                ["", "", "", #""\#r\#n""#],
                                ["5", #""A\#rh,me\#nd""#, "Egypt", #""\#r""#],
                                ["6", #""Man""olo""#, "México", "100_000"]]
        /// Exactly the same data as `contentEdgeCases`, but the quotes delimiting the beginning and end of a field have been removed.
        ///
        /// It is tipically used to check the result of parsing `contentEdgeCases`.
        static let unescapedEdgeCases = [
                                ["", "Marcos", "Spaiñ", "99"],
                                ["2", "Marine-Anaïs", #"Fra"nce"#, ""],
                                ["", "", "", ""],
                                ["4", "Pei", "China", "\n"],
                                ["", "", "", "\r\n"],
                                ["5", "A\rh,me\nd", "Egypt", "\r"],
                                ["6", #"Man"olo"#, "México", "100_000"]]
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

extension ReaderTests {
    /// Tests the correct parsing of an empty CSV.
    func testEmpty() throws {
        let parsed = try CSVReader.parse(input: "", configuration: .init())
        XCTAssertTrue(parsed.headers.isEmpty)
        XCTAssertTrue(parsed.rows.isEmpty)
    }

    /// Tests the correct parsing of a single value CSV.
    func testSingleValue() throws {
        let delimiters: Delimiter.Pair = (",", "\n")
        let input = [["Marine-Anaïs"]]
        
        let parsed = try CSVReader.parse(input: TestData.toCSV(input, delimiters: delimiters)) {
            $0.delimiters = delimiters
            $0.headerStrategy = .none
        }
        
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
        let (headers, content) = (TestData.headers, TestData.content)
        
        // The actual testing implementation.
        let work: (_ configuration: CSVReader.Configuration, _ encoded: Encoded) throws -> Void = {
            let resultA = try CSVReader.parse(input: $1.string, configuration: $0)
            let resultB = try CSVReader.parse(input: $1.data, configuration: $0)
            
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
//                    case .unknown: return XCTFail("Testing header inference is not yet supported")
                    }
                    
                    let string = TestData.toCSV(input, delimiters: pair)
                    let encoded: Encoded = (string, string.data(using: .utf8)!)
                    
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
        let (headers, content) = (TestData.headers, TestData.edgeCases)
        let unescapedContent = TestData.unescapedEdgeCases
        
        // The actual testing implementation.
        let work: (_ configuration: CSVReader.Configuration, _ encoded: Encoded) throws -> Void = {
            let resultA = try CSVReader.parse(input: $1.string, configuration: $0)
            let resultB = try CSVReader.parse(input: $1.data, configuration: $0)
            
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
//                    case .unknown: return XCTFail("Testing header inference is not yet supported")
                    }
                    
                    let string = TestData.toCSV(input, delimiters: pair)
                    let encoded: Encoded = (string, string.data(using: .utf8)!)
                    
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
        let (headers, content) = (TestData.headers, TestData.content)
        let input = ([headers] + content).mappingRandomFields(count: 5) { [quote = Character("\"")] in
            guard !$0.hasPrefix(String(quote)) else { return $0 }
            
            var field = $0
            field.insert(quote, at: field.startIndex)
            field.append(quote)
            return field
        }
        
        // The actual testing implementation.
        let work: (_ configuration: CSVReader.Configuration, _ encoded: Encoded) throws -> Void = {
            let resultA = try CSVReader.parse(input: $1.string, configuration: $0)
            let resultB = try CSVReader.parse(input: $1.data, configuration: $0)
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
                
                let string = TestData.toCSV(input, delimiters: pair)
                let encoded: Encoded = (string, string.data(using: .utf8)!)
                
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
        let (headers, content) = (TestData.headers, TestData.content)
        let input = ([headers] + content).removingRandomFields(count: 2)
        // Iterate through all configuration values.
        for r in rowDelimiters {
            for f in fieldDelimiters {
                let pair: Delimiter.Pair = (f, r)
                
                let string = TestData.toCSV(input, delimiters: pair)
                let encoded: Encoded = (string, string.data(using: .utf8)!)
                
                for p in presamples {
                    var c = CSVReader.Configuration()
                    c.delimiters = pair
                    c.headerStrategy = .firstLine
                    c.presample = p
                    XCTAssertThrowsError(try CSVReader.parse(input: encoded.string, configuration: c))
                    XCTAssertThrowsError(try CSVReader.parse(input: encoded.data, configuration: c))
                }
            }
        }
    }
}

// MARK: -

fileprivate extension Array where Element == [String] {
    /// Removes a random field from a random row.
    /// - parameter num: The number of random fields to remove.
    mutating func removeRandomFields(count: Int = 1) {
        guard !self.isEmpty && !self.first!.isEmpty else {
            fatalError("The receiving rows cannot be empty.")
        }
        
        for _ in 0..<count {
            let selectedRow = Int.random(in: 0..<self.count)
            let selectedField = Int.random(in: 0..<self[selectedRow].count)
            
            let _ = self[selectedRow].remove(at: selectedField)
        }
    }
    
    /// Copies the receiving array and removes from it a random field from a random row.
    /// - parameter num: The number of random fields to remove.
    /// - returns: A copy of the receiving array lacking `count` number of fields.
    func removingRandomFields(count: Int = 1) -> [[String]] {
        var result = self
        result.removeRandomFields(count: count)
        return result
    }

    /// Transform a random field into the value returned in the argument closure.
    /// - parameter num: The number of random fields to modify.
    mutating func mapRandomFields(count: Int = 1, _ transform: (String) -> String) {
        guard !self.isEmpty && !self.first!.isEmpty else {
            fatalError("The receiving rows cannot be empty.")
        }
        
        for _ in 0..<count {
            let selectedRow = Int.random(in: 0..<self.count)
            let selectedField = Int.random(in: 0..<self[selectedRow].count)
            
            self[selectedRow][selectedField] = transform(self[selectedRow][selectedField])
        }
    }
    
    /// Copies the receiving array and transforms a random field from it into another value.
    /// - parameter num: The number of random fields to modify.
    /// - returns: A copy of the receiving array with the `count` number of fields modified.
    func mappingRandomFields(count: Int = 1, _ transform: (String) -> String) -> [[String]] {
        var result = self
        result.mapRandomFields(count: count, transform)
        return result
    }
}

