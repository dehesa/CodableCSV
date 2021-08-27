import XCTest
import CodableCSV

/// Check support for encoding/decoding numeric Booleans.
final class CodableNumericBoolTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension CodableNumericBoolTests {
  /// Representation of a CSV row exclusively composed of Booleans.
  private struct _Row: Codable, Equatable {
    var a: Bool
    var b: Bool
    var c: Bool?
  }
}

extension CodableNumericBoolTests {
  /// Tests the regular numeric Boolean encoding/decoding.
  func testRegularUsage() throws {
    let rows = [_Row(a: true,  b: false, c: nil),
                _Row(a: true,  b: true,  c: false),
                _Row(a: false, b: false, c: true)]
    let string = """
            a,b,c
            1,0,
            1,1,0
            0,0,1
            """.appending("\n")


    let encoder = CSVEncoder {
      $0.headers = ["a", "b", "c"]
      $0.boolStrategy = .numeric
    }
    XCTAssertEqual(string, try encoder.encode(rows, into: String.self))

    let decoder = CSVDecoder {
      $0.headerStrategy = .firstLine
      $0.boolStrategy = .numeric
    }
    XCTAssertEqual(rows, try decoder.decode([_Row].self, from: string.data(using: .utf8)!))

    let shuffledString = """
            c,a,b
            ,1,0
            0,1,1
            1,0,0
            """.appending("\n")
    XCTAssertEqual(rows, try decoder.decode([_Row].self, from: shuffledString.data(using: .utf8)!))
  }

  /// Tests the error throwing/handling.
  func testThrows() throws {
    // b = nil on 2nd row, must throw an exception.
    let data = """
            a,b,c
            1,0,
            1,,0
            """.data(using: .utf8)!

    let decoder = CSVDecoder {
      $0.headerStrategy = .firstLine
      $0.boolStrategy = .numeric
    }
    XCTAssertThrowsError(try decoder.decode([_Row].self, from: data))
  }

}

