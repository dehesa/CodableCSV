import XCTest
import CodableCSV

/// Check support for encoding/decoding floating-points.
final class CodableFloatingPointTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension CodableFloatingPointTests {
  /// Representation of a CSV row.
  private struct _Student: Codable, Equatable {
    /// A student's name.
    var name: String
    /// A student's age.
    var age: Double
  }
}

extension CodableFloatingPointTests {
  /// Tests the regular floating-point encoding/decoding.
  func testRegularUsage() throws {
    let rows = [_Student(name: "Heidrun", age: 27.3),
                _Student(name: "Gudrun", age: 62.0008)]

    let encoder = CSVEncoder { $0.headers = ["name", "age"] }
    let data = try encoder.encode(rows, into: Data.self)

    let decoder = CSVDecoder { $0.headerStrategy = .firstLine }
    let result = try decoder.decode([_Student].self, from: data)
    XCTAssertEqual(rows, result)
  }

  /// Tests the error throwing/handling.
  func testThrows() throws {
    let rows = [_Student(name: "Heidrun", age: 27.3),
                _Student(name: "Gudrun", age: 62.0008),
                _Student(name: "Brunhilde", age: .infinity)]

    let encoder = CSVEncoder { $0.headers = ["name", "age"] }
    XCTAssertThrowsError(try encoder.encode(rows, into: Data.self))

    let decoder = CSVDecoder { $0.headerStrategy = .firstLine }
    let data = """
            name,age
            Heidrun,27.3
            Gudrun,62.0008
            Brunhilde,inf
            """.data(using: .utf8)!
    XCTAssertThrowsError(try decoder.decode([_Student].self, from: data))
  }

  /// Tests the the non conforming floating-point conversions.
  func testNonConformity() throws {
    let rows = [_Student(name: "Heidrun", age: 27.3),
                _Student(name: "Gudrun", age: 62.0008),
                _Student(name: "Brunhilde", age: .infinity)]

    let encoder = CSVEncoder {
      $0.headers = ["name", "age"]
      $0.nonConformingFloatStrategy = .convert(positiveInfinity: "+∞", negativeInfinity: "-∞", nan: "NaN")
    }
    let data = try encoder.encode(rows, into: Data.self)

    let decoder = CSVDecoder {
      $0.headerStrategy = .firstLine
      $0.nonConformingFloatStrategy = .convert(positiveInfinity: "+∞", negativeInfinity: "-∞", nan: "NaN")
    }
    let result = try decoder.decode([_Student].self, from: data)
    XCTAssertEqual(rows, result)
  }
}
