@testable import CodableCSV
import XCTest

final class ReaderInferenceTests: XCTestCase {
  private enum _TestData {
    /// A CSV row representing a header row (4 fields).
    static let headers   =  ["seq", "Name", "Country", "Number Pair"]
    /// Small amount of regular CSV rows (4 fields per row).
    static let content  =  [["1", "Marcos", "Spain", "99"],
                            ["2", "Kina", "Papua New Guinea", "88"],
                            ["3", "Alex", "Germany", "77"],
                            ["4", "Marine-Anaïs", "France", "66"]]

    /// Some longer CSV rows
    static let longContent = [
      ["ff60766c-08e7-4db4-bfd3-dcc60c15251f", "foofoofoo", "barbarbar", "bazbazbaz"],
      ["f9165d00-03fc-4d8d-838c-1fba1d26d92d", "foofoofoo", "barbarbar", "bazbazbaz"],
    ]

    /// Encodes the test data into a Swift `String`.
    /// - parameter sample:
    /// - parameter delimiters: Unicode scalars to use to mark fields and rows.
    /// - returns: Swift String representing the CSV file.
    static func toCSV(_ sample: [[String]], delimiters: Delimiter.Pair) -> String {
      let (f, r) = (delimiters.field.description, delimiters.row.description)
      return sample.map { $0.joined(separator: f) }.joined(separator: r).appending(r)
    }
  }
}

extension ReaderInferenceTests {
  func testInference() throws {
    let fieldDelimiters: [Delimiter.Field] = [",", ";", "|", "\t"]

    var configuration = CSVReader.Configuration()
    configuration.delimiters = (field: nil, row: "\n")

    for fieldDelimiter in fieldDelimiters {
      let testString = _TestData.toCSV(_TestData.content, delimiters: (fieldDelimiter, "\n"))
      let result = try CSVReader.decode(input: testString, configuration: configuration)
      XCTAssertEqual(result.rows, _TestData.content, "Delimiter: \(fieldDelimiter)")
    }
  }

  func testInference_longRows() throws {
    let fieldDelimiters: [Delimiter.Field] = [",", ";", "|", "\t"]

    var configuration = CSVReader.Configuration()
    configuration.delimiters = (field: nil, row: "\n")

    for fieldDelimiter in fieldDelimiters {
      let testString = _TestData.toCSV(_TestData.longContent, delimiters: (fieldDelimiter, "\n"))
      let result = try CSVReader.decode(input: testString, configuration: configuration)
      XCTAssertEqual(result.rows, _TestData.longContent)
    }
  }
}
