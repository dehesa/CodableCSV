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
        struct KeyedStudent: Encodable {
            var name: String
            var age: Int
            var hasPet: Bool
        }
        
        struct UnkeyedStudent: Encodable {
            var name: String
            var age: Int
            var hasPet: Bool
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(self.name)
                try container.encode(self.age)
                try container.encode(self.hasPet)
            }
        }
        
        struct School<S:Encodable>: Encodable {
            var students: [S]
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
        // The configuration values to be tests.
        let encoding: String.Encoding = .utf8
        let bomStrategy: Strategy.BOM = .never
        let delimiters: Delimiter.Pair = (",", "\n")
        let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll /*, .unfulfilled, .sequential*/]
        // The data used for testing.
        let value: [[String]] = []

        for s in bufferStrategies {
            var configuration = CSVEncoder.Configuration()
            configuration.encoding = encoding
            configuration.bomStrategy = bomStrategy
            configuration.delimiters = delimiters
            configuration.bufferingStrategy = s

            let encoder = CSVEncoder(configuration: configuration)
            let data = try encoder.encode(value)
            XCTAssertTrue(data.isEmpty)
        }
    }
    
    /// Tests the encoding of a single empty field in a CSV file.
    func testSingleField() throws {
        // The configuration values to be tests.
        let encoding: String.Encoding = .utf8
        let bomStrategy: Strategy.BOM = .never
        let delimiters: Delimiter.Pair = (",", "\n")
        let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll /*, .unfulfilled, .sequential*/]
        // The data used for testing.
        let value: [[String]] = [[.init()]]

        for s in bufferStrategies {
            var configuration = CSVEncoder.Configuration()
            configuration.encoding = encoding
            configuration.bomStrategy = bomStrategy
            configuration.delimiters = delimiters
            configuration.bufferingStrategy = s

            let encoder = CSVEncoder(configuration: configuration)
            let data = try encoder.encode(value)
            let string = String(data: data, encoding: encoding)!
            XCTAssertEqual(string, "\"\"\(delimiters.row)")
        }
    }
    
    /// Tests the encoding of an empty custom type.
    func testEmptyCustomType() throws {
        // The configuration values to be tests.
        let encoding: String.Encoding = .utf8
        let bomStrategy: Strategy.BOM = .never
        let delimiters: Delimiter.Pair = (",", "\n")
        let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll /*, .unfulfilled, .sequential*/]
        // The data used for testing.
        let school = TestData.School<TestData.KeyedStudent>(students: [])
        
        for s in bufferStrategies {
            var configuration = CSVEncoder.Configuration()
            configuration.encoding = encoding
            configuration.bomStrategy = bomStrategy
            configuration.delimiters = delimiters
            configuration.bufferingStrategy = s
            
            let encoder = CSVEncoder(configuration: configuration)
            let data = try encoder.encode(school)
            XCTAssertTrue(data.isEmpty)
        }
    }
    
    /// Tests a single custom type encoding (with headers).
    func testSingleCustomType() throws {
        // The configuration values to be tests.
        let encoding: String.Encoding = .utf8
        let bomStrategy: Strategy.BOM = .never
        let delimiters: Delimiter.Pair = (",", "\n")
        let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll /*, .unfulfilled, .sequential*/]
        let headers = ["name", "age", "hasPet"]
        // The data used for testing.
        let student = TestData.KeyedStudent(name: "Marcos", age: 111, hasPet: true)
        let school = TestData.School<TestData.KeyedStudent>(students: [student])
        
        for s in bufferStrategies {
            var configuration = CSVEncoder.Configuration()
            configuration.encoding = encoding
            configuration.bomStrategy = bomStrategy
            configuration.delimiters = delimiters
            configuration.bufferingStrategy = s
            configuration.headers = headers
            
            let encoder = CSVEncoder(configuration: configuration)
            let string = try encoder.encode(school, into: String.self)
            let content = string.split(separator: .init(delimiters.row.rawValue.first!))
            
            let encodedHeaders = content[0].split(separator: Character(delimiters.field.rawValue.first!)).map { String($0) }
            XCTAssertEqual(headers, encodedHeaders)
            
            let encodedValues = content[1].split(separator: Character(delimiters.field.rawValue.first!)).map { String($0) }
            XCTAssertEqual(student.name, encodedValues[0])
            XCTAssertEqual(String(student.age), encodedValues[1])
            XCTAssertEqual(String(student.hasPet), encodedValues[2])
        }
    }
    
    /// Tests a single custom type encoding (with NO headers).
    func testSingleCustomTypeNoHeaders() throws {
        // The configuration values to be tests.
        let encoding: String.Encoding = .utf8
        let bomStrategy: Strategy.BOM = .never
        let delimiters: Delimiter.Pair = (",", "\n")
        let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll /*, .unfulfilled, .sequential*/]
        let headers: [String] = []
        // The data used for testing.
        let student = TestData.UnkeyedStudent(name: "Marcos", age: 111, hasPet: true)
        let school = TestData.School<TestData.UnkeyedStudent>(students: [student])
        
        for s in bufferStrategies {
            var configuration = CSVEncoder.Configuration()
            configuration.encoding = encoding
            configuration.bomStrategy = bomStrategy
            configuration.delimiters = delimiters
            configuration.bufferingStrategy = s
            configuration.headers = headers
            
            let encoder = CSVEncoder(configuration: configuration)
            let string = try encoder.encode(school, into: String.self)
            let content = string.split(separator: .init(delimiters.row.rawValue.first!))

            let encodedValues = content[0].split(separator: Character(delimiters.field.rawValue.first!)).map { String($0) }
            XCTAssertEqual(student.name, encodedValues[0])
            XCTAssertEqual(String(student.age), encodedValues[1])
            XCTAssertEqual(String(student.hasPet), encodedValues[2])
        }
    }
}
