import XCTest
import CodableCSV

/// Check support for handling bad input
final class DecodingBadInputTests: XCTestCase {
    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension DecodingBadInputTests {
    /// Representation of a CSV row containing a couple of strings.
    private struct _Row: Codable, Equatable {
        var x: String
        var y: String
    }
}

extension DecodingBadInputTests {
    /// Tests bad quoting resulting in too many fields in a particular row
    func testBadQuoting() {
        let input = """
            x,y
            A,A A
            C,C, C
            D,D D
            """
        let decoder = CSVDecoder { $0.headerStrategy = .firstLine }
        XCTAssertThrowsError(try decoder.decode([_Row].self, from: input))
    }

    /// Tests a CSV with a header with three fields (one of them being empty) and subsequent rows with two fields.
    func testIllFormedHeader() {
        let input = """
            x,y,
            A,A A
            B,"B, B"
            """
        let decoder = CSVDecoder { $0.headerStrategy = .firstLine }
        XCTAssertThrowsError(try decoder.decode([_Row].self, from: input))
    }
}
