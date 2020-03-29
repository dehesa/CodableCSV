import XCTest
import CodableCSV

/// Tests checking the regular encoding usage.
final class EncodingRegularUsageTests: XCTestCase {
    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension EncodingRegularUsageTests {
    /// Test data used throughout this `XCTestCase`.
    private enum TestData {
        struct Student: Encodable {
            var name: String
            var age: Int
            var hasPet: Bool
        }
        
        struct School: Encodable {
            var students: [Student]
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                for student in self.students { try container.encode(student) }
            }
        }
    }
}

// MARK: -

extension EncodingRegularUsageTests {
    /// Tests the encoding of an empty.
    func testEmptyFile() throws {
//        // The configuration values to be tests.
//        let encoding: String.Encoding = .utf8
//        let bomStrategy: Strategy.BOM = .never
//        let delimiters: Delimiter.Pair = (",", "\n")
//        let bufferStrategies: [Strategy.EncodingBuffer] = [.unfulfilled, .sequential]
//        // The data used for testing.
//        let value: [[String]] = []
//
//        for s in bufferStrategies {
//            var configuration = CSVEncoder.Configuration()
//            configuration.encoding = encoding
//            configuration.bomStrategy = bomStrategy
//            configuration.delimiters = delimiters
//            configuration.bufferingStrategy = s
//
//            let encoder = CSVEncoder(configuration: configuration)
//            let data = try encoder.encode(value)
//            XCTAssertTrue(data.isEmpty)
//        }
    }
    
    /// Tests the encoding of a single empty field in a CSV file.
    func testSingleField() throws {
//        // The configuration values to be tests.
//        let encoding: String.Encoding = .utf8
//        let bomStrategy: Strategy.BOM = .never
//        let delimiters: Delimiter.Pair = (",", "\n")
//        let bufferStrategies: [Strategy.EncodingBuffer] = [.unfulfilled, .sequential]
//        // The data used for testing.
//        let value: [[String]] = [[""]]
//
//        for s in bufferStrategies {
//            var configuration = CSVEncoder.Configuration()
//            configuration.encoding = encoding
//            configuration.bomStrategy = bomStrategy
//            configuration.delimiters = delimiters
//            configuration.bufferingStrategy = s
//
//            let encoder = CSVEncoder(configuration: configuration)
//            let data = try encoder.encode(value)
//            XCTAssertTrue(data.isEmpty)
//        }
    }
    
    /// Tests the encoding of an empty custom type.
    func testEmptyCustomType() throws {
//        // The configuration values to be tests.
//        let encoding: String.Encoding = .utf8
//        let bomStrategy: Strategy.BOM = .never
//        let delimiters: Delimiter.Pair = (",", "\n")
//        let bufferStrategies: [Strategy.EncodingBuffer] = [.unfulfilled, .sequential]
//        // The data used for testing.
//        let school = TestData.School(students: [])
//        
//        for s in bufferStrategies {
//            var configuration = CSVEncoder.Configuration()
//            configuration.encoding = encoding
//            configuration.bomStrategy = bomStrategy
//            configuration.delimiters = delimiters
//            configuration.bufferingStrategy = s
//            
//            let encoder = CSVEncoder(configuration: configuration)
//            let data = try encoder.encode(school)
//            XCTAssertTrue(data.isEmpty)
//        }
    }
}
