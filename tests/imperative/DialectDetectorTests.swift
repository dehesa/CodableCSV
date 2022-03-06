@testable import CodableCSV
import XCTest

final class DialectDetectorTests: XCTestCase {}

// MARK: - Tests for detectDialect

extension DialectDetectorTests {
  func test_detectDialect() throws {
    // Adapted from CPython
    // See: https://github.com/python/cpython/blob/f4c03484da59049eb62a9bf7777b963e2267d187/Lib/test/test_csv.py#L1039
    let dialects = [
      (
        """
        Harry's, Arlington Heights, IL, 2/1/03, Kimi Hayes
        Shark City, Glendale Heights, IL, 12/28/02, Prezence
        Tommy's Place, Blue Island, IL, 12/28/02, Blue Sunday/White Crow
        Stonecutters Seafood and Chop House, Lemont, IL, 12/19/02, Week Back
        """,
        DialectDetector.Dialect(fieldDelimiter: ",")
      ),
//      (
//        """
//        'Harry''s':'Arlington Heights':'IL':'2/1/03':'Kimi Hayes'
//        'Shark City':'Glendale Heights':'IL':'12/28/02':'Prezence'
//        'Tommy''s Place':'Blue Island':'IL':'12/28/02':'Blue Sunday/White Crow'
//        'Stonecutters ''Seafood'' and Chop House':'Lemont':'IL':'12/19/02':'Week Back'
//        """,
//        DialectDetector.Dialect(fieldDelimiter: ":")
//      ),
    ]

    for (csv, expectedDialect) in dialects {
      let dialect = DialectDetector.detectDialect(stringScalars: Array(csv.unicodeScalars))
      XCTAssertEqual(dialect, expectedDialect, csv)
    }
  }
}

// MARK: - Tests for calculatePatternScore

extension DialectDetectorTests {
  // Adapted from CleverCSV
  // See: https://github.com/alan-turing-institute/CleverCSV/blob/master/tests/test_unit/test_detect_pattern.py#L160-L195
  func test_calculatePatternScore() throws {
    let dialectScores: [(DialectDetector.Dialect, Double)] = [
      (.init(fieldDelimiter: ","), 7 / 4),
      (.init(fieldDelimiter: ";"), 10 / 3),
    ]
    let csv = #"""
      7,5; Mon, Jan 12;6,40
      100; Fri, Mar 21;8,23
      8,2; Thu, Sep 17;2,71
      538,0;;7,26
      "NA"; Wed, Oct 4;6,93
      """#

    for (dialect, expectedScore) in dialectScores {
      let score = DialectDetector.calculatePatternScore(stringScalars: Array(csv.unicodeScalars), dialect: dialect)
      XCTAssertEqual(score, expectedScore, "Delimiter: \(dialect.fieldDelimiter)")
    }
  }

  /// Demonstrates that it is useful to check for the correctness of the CSV
  /// that results from a particular dialect because there may be instances where
  /// two field delimiters both get a score of 1.0 despite one of them leading to
  /// a valid CSV and the other leading to a malformed CSV
  func test_calculatePatternScore_TieBreaking() {
    let csv = """
      foo;,bar
      baz;,"boo"
      """

    let dialectErrors: [(DialectDetector.Dialect, [DialectDetector.Abstraction.Error])] = [
      (.init(fieldDelimiter: ","), []),
      (.init(fieldDelimiter: ";"), [.invalidEscapeCharacterPosition]),
    ]

    for (dialect, expectedErrors) in dialectErrors {
      let msg = "Delimiter: \(dialect.fieldDelimiter)"
      let scalars = Array(csv.unicodeScalars)
      let score = DialectDetector.calculatePatternScore(stringScalars: scalars, dialect: dialect)
      XCTAssertEqual(score, 1.0, msg)
      let (abstraction, errors) = DialectDetector.makeAbstraction(stringScalars: scalars, dialect: dialect)
      XCTAssertEqual(abstraction, [.cell, .fieldDelimiter, .cell, .rowDelimiter, .cell, .fieldDelimiter, .cell])
      XCTAssertEqual(errors, expectedErrors, msg)
    }
  }
}

// MARK: - Tests for makeAbstraction

extension DialectDetectorTests {
  func test_makeAbstraction() throws {
    let abstractions: [(String, [DialectDetector.Abstraction])] = [
      ("", []),
      ("foo", [.cell]),

      (",", [.cell, .fieldDelimiter, .cell]),
      (",,", [.cell, .fieldDelimiter, .cell, .fieldDelimiter, .cell]),

      ("\n", [.cell, .rowDelimiter]),
      ("\n\n", [.cell, .rowDelimiter, .cell, .rowDelimiter]),

      (",\n,", [.cell, .fieldDelimiter, .cell, .rowDelimiter, .cell, .fieldDelimiter, .cell]),
      (",foo\n,bar", [.cell, .fieldDelimiter, .cell, .rowDelimiter, .cell, .fieldDelimiter, .cell]),
    ]
    let dialect = DialectDetector.Dialect(fieldDelimiter: ",")

    for (csv, expected) in abstractions {
      let (abstraction, _) = DialectDetector.makeAbstraction(stringScalars: Array(csv.unicodeScalars), dialect: dialect)
      XCTAssertEqual(abstraction, expected, csv)
    }
  }

  func test_makeAbstraction_HandlesEscaping() throws {
    let escapingAbstractions: [(String, [DialectDetector.Abstraction])] = [
      (#"  "foo",bar                     "#, [.cell, .fieldDelimiter, .cell]),
      (#"  "foo ""quoted"" \n ,bar",baz  "#, [.cell, .fieldDelimiter, .cell]),
      (#"  a,"bc""d""e""f""a",\n         "#, [.cell, .fieldDelimiter, .cell, .fieldDelimiter, .cell]),
    ]
    let dialect = DialectDetector.Dialect(fieldDelimiter: ",")
    for (csv, expected) in escapingAbstractions {
      let strippedCSV = csv.trimmingCharacters(in: .whitespaces)
      let (abstraction, _) = DialectDetector.makeAbstraction(stringScalars: Array(strippedCSV.unicodeScalars), dialect: dialect)
      XCTAssertEqual(abstraction, expected, csv)
    }
  }

  func test_makeAbstraction_HandlesInvalidEscaping() throws {
    let dialect = DialectDetector.Dialect(fieldDelimiter: ",")
    let malformedCSVs: [(String, [DialectDetector.Abstraction])] = [
      // escaping
      (#"  foo,x"bar"  "#, [.cell, .fieldDelimiter, .cell]),
      (#"  foo,"bar"x  "#, [.cell, .fieldDelimiter, .cell]),
      (#"  foo,"bar    "#, [.cell, .fieldDelimiter, .cell]),
      // different number of fields per row
      ("foo,bar\n\n", [.cell, .fieldDelimiter, .cell, .rowDelimiter, .cell, .rowDelimiter]),
    ]

    for (csv, expected) in malformedCSVs {
      let strippedCSV = csv.trimmingCharacters(in: .whitespaces)
      let (abstraction, _) = DialectDetector.makeAbstraction(stringScalars: Array(strippedCSV.unicodeScalars), dialect: dialect)
      XCTAssertEqual(abstraction, expected, strippedCSV)
    }
  }
}
