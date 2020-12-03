import XCTest
import CodableCSV

/// Tests checking support for encoding/decoding numeric booleans.
final class CodableNumericBoolTests: XCTestCase {
    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension CodableNumericBoolTests {
    private struct _Object: Codable, Equatable {
        var value1: Bool
        var value2: Bool
        var value3: Bool?
    }
    
    private static let list: [_Object] = [
        .init(value1: true, value2: false, value3: nil),
        .init(value1: true, value2: true, value3: false),
        .init(value1: false, value2: false, value3: true)
    ]
    
    private static let csvOKHeader1 =
        """
        value1,value2,value3
        1,0,
        1,1,0
        0,0,1

        """
    private static let csvOKHeader2 =
        """
        value3,value1,value2
        ,1,0
        0,1,1
        1,0,0

        """
}

extension CodableNumericBoolTests {
    /// Test the regular numeric bool coding
    func testRegularUsage() throws {
        guard let data = Self.csvOKHeader1.data(using: .utf8) else {
            fatalError()
        }
        let decoder = CSVDecoder {
            $0.headerStrategy = .firstLine
            $0.boolStrategy = .numeric
        }
        var result = try decoder.decode([_Object].self, from: data)
        XCTAssertEqual(Self.list, result)
        
        guard let data2 = Self.csvOKHeader2.data(using: .utf8) else {
            fatalError()
        }

        result = try decoder.decode([_Object].self, from: data2)
        XCTAssertEqual(Self.list, result)
        
        let encoder = CSVEncoder {
            $0.headers = ["value1", "value2", "value3"]
            $0.boolStrategy = .numeric
        }
        
        let csv = try encoder.encode(result, into: String.self)
        XCTAssertEqual(Self.csvOKHeader1, csv)

    }
    
    /// Test nil failure
    func testThrows() throws {
        // value2 = nil on 2nd row, must throw an exception
        guard let data = """
            value1,value2,value3
            1,0,
            1,,0
            """.data(using: .utf8) else {
            fatalError()
        }
        let decoder = CSVDecoder {
            $0.headerStrategy = .firstLine
            $0.boolStrategy = .numeric
        }
        XCTAssertThrowsError(try decoder.decode([_Object].self, from: data))
    }
    
}

