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
    /// Tests bad input, in which a row in not escaped resulting in too many fields in a particular row
    func testBadEscaping() {
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
    
    /// Tests a valid CSV file with an extra new line delimeter at the end of the file.
    func testExtraNewLine() throws {
        let input = """
            x,y
            A,AA
            B,BB
            \n
            """
        let decoder = CSVDecoder { $0.headerStrategy = .firstLine }
        XCTAssertNoThrow(try decoder.decode([_Row].self, from: input))
    }
}

extension DecodingBadInputTests {
    /// Tests CRLF delimiters with escape fields.
    func testInputCRLF() throws {
        let input = "Name\r\n\"G\"\r\n"

        let decoder = CSVDecoder {
            $0.encoding = .utf8
            $0.bufferingStrategy = .sequential
            $0.headerStrategy = .firstLine
            $0.trimStrategy = .whitespaces
            $0.delimiters.row = nil
        }
        do {
            let file = try decoder.decode([String].self, from: input)
            for row in file { print(row) }
        } catch {
            print(error)
            throw error
        }
    }

    /// Tests CRLF delimiters with escape fields.
    func testInputLF() throws {
        let input = "Name\n\"G\"\n"

        let decoder = CSVDecoder {
            $0.encoding = .utf8
            $0.bufferingStrategy = .sequential
            $0.headerStrategy = .firstLine
            $0.trimStrategy = .whitespaces
            $0.delimiters.row = nil
        }
        do {
            let file = try decoder.decode([String].self, from: input)
            for row in file { print(row) }
        } catch {
            print(error)
            throw error
        }
    }

}
