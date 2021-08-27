import XCTest
import CodableCSV

/// Tests generic and edge cases from a CSV reader perspective.
final class ReaderCollectionsTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension ReaderCollectionsTests {
  /// The test data used for this file.
  private enum _TestData {
    /// A CSV row representing a header row (4 fields).
    static let headers   =  ["seq", "Name", "Country", "Number Pair"]
    /// Small amount of regular CSV rows (4 fields per row).
    static let content  =  [["1", "Marcos", "Spain", "99"],
                            ["2", "Kina", "Papua New Guinea", "88"],
                            ["3", "Alex", "Germany", "77"],
                            ["4", "Marine-Anaïs", "France", "66"],
                            ["5", "Idan", "Israel", "55"],
                            ["6", "Frankie", "Namibia", "44"],
                            ["7", "Pei", "China", "33"],
                            ["8", "Alessa", "Peru", "22"],
                            ["9", "Sophia", "Canada", "11"]]
    /// Encodes the test data into a Swift `String`.
    /// - parameter sample:
    /// - parameter delimiters: Unicode scalars to use to mark fields and rows.
    /// - returns: Swift String representing the CSV file.
    static func toCSV(_ sample: [[String]], delimiters: Delimiter.Pair) -> String {
      let (f, r) = (delimiters.field.description, delimiters.row.description)
      return sample.map { $0.joined(separator: f) }.joined(separator: r).appending(r)
    }
  }

  private typealias _Encoded = (string: String, data: Data)
}

// MARK: -

extension ReaderCollectionsTests {
  /// Tests the `Record` structure regular usage (i.e. subscripts, collection syntax, lookups, etc.).
  func testRecords() throws {
    // A. The configuration values to be tested.
    let delimiters: Delimiter.Pair = (field: ",", row: "\n")
    let headerStrategy: Strategy.Header = .firstLine
    // B. The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    let sample = _TestData.toCSV([headers] + content, delimiters: delimiters)

    let reader = try CSVReader(input: sample) {
      $0.delimiters = delimiters
      $0.headerStrategy = headerStrategy
    }

    var (result, rowIndex) = ([CSVReader.Record](), 0)
    while let record = try reader.readRecord() {
      result.append(record)
      XCTAssertEqual(record.count, headers.count)
      XCTAssertEqual(content[rowIndex], record.row)
      XCTAssertTrue(record == content[rowIndex])

      for (fieldIndex, header) in headers.enumerated() {
        XCTAssertEqual(content[rowIndex][fieldIndex], record[header])
      }

      for (fieldIndex, field) in record.enumerated() {
        XCTAssertEqual(content[rowIndex][fieldIndex], field)
      }
      rowIndex += 1
    }
  }

  /// Tests the `FileView` structure regular usage.
  func testFileView() throws {
    // A. The configuration values to be tested.
    let delimiters: Delimiter.Pair = (field: ",", row: "\n")
    let headerStrategy: Strategy.Header = .firstLine
    // B. The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    let sample = _TestData.toCSV([headers] + content, delimiters: delimiters)

    let file = try CSVReader.decode(input: sample) {
      $0.delimiters = delimiters
      $0.headerStrategy = headerStrategy
    }

    XCTAssertEqual(headers, file.headers)
    XCTAssertEqual(content, file.rows)

    for (rowIndex, row) in content.enumerated() {
      XCTAssertEqual(row, file[rowIndex])
      XCTAssertEqual(row, file.records[rowIndex].row)

      for (fieldIndex, field) in row.enumerated() {
        XCTAssertEqual(field, file[row: rowIndex, column: headers[fieldIndex]]!)
      }
    }

    for (columnIndex, columnName) in headers.enumerated() {
      XCTAssertEqual(file[column: columnIndex], content.map { $0[columnIndex] })
      XCTAssertEqual(file[column: columnName]!, content.map { $0[columnIndex] })
    }
  }
}
