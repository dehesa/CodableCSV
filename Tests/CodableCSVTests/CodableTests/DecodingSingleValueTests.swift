import XCTest
import CodableCSV

/// Tests for the decodable school data tests.
final class DecodingSingleValueDecodingTests: XCTestCase {
    // List of all tests to run through SPM.
    static let allTests = [
        ("testEmptyFile", testEmptyFile),
        ("testSingleValueFile", testSingleValueFile),
        ("testSingleValueRows", testSingleValueRows)
    ]
        
    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension DecodingSingleValueDecodingTests {
    /// Test data used throughout this `XCTestCase`.
    private enum TestData {
        /// Configuration used to generated the CSV data.
        static let configuration = DecoderConfiguration(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headerStrategy: .none)
    }
}

extension DecodingSingleValueDecodingTests {
    private struct EmptyFile: Decodable {
        init(from decoder: Decoder) throws {
            let fileContainer = try decoder.unkeyedContainer()
            XCTAssertTrue(fileContainer.isAtEnd)
        }
    }
    
    func testEmptyFile() throws {
        let emptyData = "".data(using: .utf8)!
        let decoder = CSVDecoder(configuration: TestData.configuration)
        let _ = try decoder.decode(EmptyFile.self, from: emptyData, encoding: .utf8)
    }
}

extension DecodingSingleValueDecodingTests {
    private struct SingleStringValueFile: Decodable {
        let value: String
        
        init(from decoder: Decoder) throws {
            var fileContainer = try decoder.unkeyedContainer()
            self.value = try fileContainer.decode(String.self)
            XCTAssertTrue(fileContainer.isAtEnd)
        }
    }
    
    private struct SingleInt32ValueFile: Decodable {
        let value: Int32
        
        init(from decoder: Decoder) throws {
            let fileContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.value = try fileContainer.decode(Int32.self, forKey: .value)
        }
        
        private enum CodingKeys: Int, CodingKey {
            case value = 0
        }
    }
    
    private struct SingleUInt32ValueFile: Decodable {
        let value: UInt32
        
        init(from decoder: Decoder) throws {
            let wrapperContainer = try decoder.singleValueContainer()
            self.value = try wrapperContainer.decode(UInt32.self)
        }
    }
    
    func testSingleValueFile() throws {
        let rowDelimiter = TestData.configuration.delimiters.row.stringValue!
        
        do {
            let data = ("Grumpy" + rowDelimiter).data(using: .utf8)!
            let decoder = CSVDecoder(configuration: TestData.configuration)
            let _ = try decoder.decode(SingleStringValueFile.self, from: data, encoding: .utf8)
        }
        
        do {
            let data = ("34" + rowDelimiter).data(using: .utf8)!
            let decoder = CSVDecoder(configuration: TestData.configuration)
            let _ = try decoder.decode(SingleInt32ValueFile.self, from: data, encoding: .utf8)
        }
        
        do {
            let data = ("77" + rowDelimiter).data(using: .utf8)!
            let decoder = CSVDecoder(configuration: TestData.configuration)
            let _ = try decoder.decode(SingleUInt32ValueFile.self, from: data, encoding: .utf8)
        }
    }
}

extension DecodingSingleValueDecodingTests {
    private struct FileLevel: Decodable {
        private(set) var values: [Int8] = []
        
        init(from decoder: Decoder) throws {
            var fileContainer = try decoder.unkeyedContainer()
            while !fileContainer.isAtEnd {
                values.append(try fileContainer.decode(Int8.self))
            }
        }
    }
    
    private struct RowLevel: Decodable {
        private(set) var values: [Int8] = []
        
        init(from decoder: Decoder) throws {
            var fileContainer = try decoder.unkeyedContainer()
            while !fileContainer.isAtEnd {
                var rowContainer = try fileContainer.nestedUnkeyedContainer()
                while !rowContainer.isAtEnd {
                    values.append(try rowContainer.decode(Int8.self))
                }
            }
        }
    }
    
    func testSingleValueRows() throws {
        let data = (0...10)
            .map { String($0) }
            .joined(separator: TestData.configuration.delimiters.row.stringValue!)
            .data(using: .utf8)!
        
        do {
            let decoder = CSVDecoder(configuration: TestData.configuration)
            let _ = try decoder.decode(FileLevel.self, from: data, encoding: .utf8)
        }
        
        do {
            let decoder = CSVDecoder(configuration: TestData.configuration)
            let _ = try decoder.decode(RowLevel.self, from: data, encoding: .utf8)
        }
    }
}
