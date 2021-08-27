import XCTest
import CodableCSV

/// Check support for handling bad input
final class ReaderBadInputTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension ReaderBadInputTests {
  /// Representation of a CSV row containing a couple of strings.
  private struct _Row: Codable, Equatable {
    var x: String
    var y: String
  }
}

extension ReaderBadInputTests {
  /// Tests bad input, in which a row in not escaped resulting in too many fields in a particular row
  func testBadEscaping() throws {
    let input = """
            x,y
            A,A A
            C,C, C
            D,D D
            """
    XCTAssertThrowsError(try CSVReader.decode(input: input) { $0.headerStrategy = .firstLine })
  }
  
  /// Tests a CSV with a header with three fields (one of them being empty) and subsequent rows with two fields.
  func testIllFormedHeader() {
    let input = """
            x,y,
            A,A A
            B,"B, B"
            """
    XCTAssertThrowsError(try CSVReader.decode(input: input) { $0.headerStrategy = .firstLine })
  }
  
  /// Tests a valid CSV file with an extra new line delimeter at the end of the file.
  func testExtraNewLine() throws {
    let input = """
            x,y
            A,AA
            B,BB
            \n
            """
    let reader = try CSVReader(input: input) { $0.headerStrategy = .firstLine }
    XCTAssertNotNil(try reader.readRow())
    XCTAssertNotNil(try reader.readRow())
    XCTAssertNil(try reader.readRow())
  }
}
