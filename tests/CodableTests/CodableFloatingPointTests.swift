import XCTest
import CodableCSV

/// Tests checking support for encoding/decoding floating-points.
final class CodableFloatingPointTests: XCTestCase {
    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension CodableFloatingPointTests {
    private struct _Student: Codable, Equatable {
        var name: String
        var age: Double
    }
}

extension CodableFloatingPointTests {
    /// Test the regular floating-point encoding/decoding.
    func testRegularUsage() throws {
        let encoder = CSVEncoder { $0.headers = ["name", "age"] }
        let students: [_Student] = [
            .init(name: "Heidrun", age: 27.3),
            .init(name: "Gudrun", age: 62.0008),
        ]
        
        let data = try encoder.encode(students, into: Data.self)
        
        let decoder = CSVDecoder { $0.headerStrategy = .firstLine }
        let result = try decoder.decode([_Student].self, from: data)
        XCTAssertEqual(students, result)
    }
    
//    /// Test the regular floating-point encoding/decoding.
//    func testThrows() throws {
//        let encoder = CSVEncoder { $0.headers = ["name", "age"] }
//        let students: [_Student] = [
//            .init(name: "Heidrun", age: 27.3),
//            .init(name: "Gudrun", age: 62.0008),
//            .init(name: "Brunhilde", age: .infinity)
//        ]
//        XCTAssertThrowsError(try encoder.encode(students, into: Data.self))
//
//        let decoder = CSVDecoder { $0.headerStrategy = .firstLine }
//        let data = """
//            name,age
//            Heidrun,27.3
//            Gudrun,62.0008
//            Brunhilde,inf
//            """.data(using: .utf8)!
//        XCTAssertThrowsError(try decoder.decode([_Student].self, from: data))
//    }
    
    /// Test the regular floating-point encoding/decoding.
    func testConversion() throws {
        let students: [_Student] = [
            .init(name: "Heidrun", age: 27.3),
            .init(name: "Gudrun", age: 62.0008),
            .init(name: "Brunhilde", age: .infinity)
        ]
        
        let encoder = CSVEncoder {
            $0.headers = ["name", "age"]
            $0.nonConformingFloatStrategy = .convert(positiveInfinity: "+∞", negativeInfinity: "-∞", nan: "NaN")
        }
        
        let data = try encoder.encode(students, into: Data.self)
        
        let decoder = CSVDecoder {
            $0.headerStrategy = .firstLine
            $0.nonConformingFloatStrategy = .convert(positiveInfinity: "+∞", negativeInfinity: "-∞", nan: "NaN")
        }
        let result = try decoder.decode([_Student].self, from: data)
        XCTAssertEqual(students, result)
    }
}
