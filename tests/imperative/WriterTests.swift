import XCTest
import CodableCSV

/// Tests generic and edge cases from a CSV writer perspective.
final class WriterTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension WriterTests {
  /// The test data used for this file.
  private enum _TestData {
    /// A CSV row representing a header row (4 fields).
    static let headers = ["seq", "Name", "Country", "Number Pair"]
    /// Small amount of regular CSV rows (4 fields per row).
    static let content = [["1", "Marcos", "Spain", "99"],
                          ["2", "Marine-Anaïs", "France", "88"],
                          ["3", "Alex", "Germany", "77"],
                          ["4", "Pei", "China", "66"]]
    /// Encodes the test data into a Swift `String`.
    /// - parameter sample: The data to be encoded as a CSV.
    /// - parameter delimiters: Unicode scalars to use to mark fields and rows.
    /// - returns: Swift String representing the CSV file.
    static func toCSV(_ sample: [[String]], delimiters: Delimiter.Pair) -> String {
      let (f, r) = (delimiters.field.description, delimiters.row.description)
      return sample.map { $0.joined(separator: f) }.joined(separator: r).appending(r)
    }
    /// Generates a URL pointing to a temporary file on the system temporary folder.
    static func generateTemporaryFileURL() -> URL {
      let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      return directoryURL.appendingPathComponent(UUID().uuidString)
    }
  }
}

// MARK: -

extension WriterTests {
  /// Test the correct encoding of an empty CSV (no headers, no content).
  func testEmpty() throws {
    // 1. Tests the data encoder.
    let dataWriter = try CSVWriter()
    try dataWriter.endEncoding()
    let data = try dataWriter.data()
    XCTAssertTrue(data.isEmpty)
    // 2. Tests the file encoder.
    let url = _TestData.generateTemporaryFileURL()
    XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: data))
    let fileWriter = try CSVWriter(fileURL: url)
    try fileWriter.endEncoding()
    try FileManager.default.removeItem(at: url)
  }

  /// Tests the correct encoding of a single CSV field.
  func testSingleField() throws {
    // A. The configuration values to be tested.
    var config = CSVWriter.Configuration()
    config.delimiters = (",", "\n")
    config.bomStrategy = .never
    // B. The data used for testing.
    let field = "Marine-Anaïs"
    // 1. Tests the full-file string decoder.
    let string = try CSVWriter.encode(rows: [[field]], into: String.self, configuration: config)
    XCTAssertEqual(string, field + config.delimiters.row.description)
    // 2. Tests the full-file data decoder.
    let data = try CSVWriter.encode(rows: [[field]], into: Data.self, configuration: config)
    XCTAssertEqual(String(data: data, encoding: .utf8)!, field + config.delimiters.row.description)
    // 3. Tests the full-file decoder.
    let url = _TestData.generateTemporaryFileURL()
    try CSVWriter.encode(rows: [[field]], into: url, configuration: config)
    XCTAssertEqual(String(data: try Data(contentsOf: url), encoding: .utf8)!, field + config.delimiters.row.description)
    try FileManager.default.removeItem(at: url)
    // 4. Tests the line reader.
    let writer = try CSVWriter()
    try writer.write(field: field)
    try writer.endRow()
    try writer.endEncoding()
    XCTAssertEqual(data, try writer.data())
  }

  /// Tests a small CSV with UTF8 encoding.
  ///
  /// All delimiters (both field and row delimiters) will be used.
  func testRegularUsage() throws {
    // A. The configuration values to be tested.
    let rowDelimiters: [Delimiter.Row] = ["\n", "\r", "\r\n", "**~**"]
    let fieldDelimiters: [Delimiter.Field] = [",", ";", "\t", "|", "||", "|-|"]
    let escapingStrategy: [Strategy.Escaping] = [.none, .doubleQuote]
    let encodings: [String.Encoding] = [.utf8, .utf16LittleEndian, .utf16BigEndian, .utf16LittleEndian, .utf32BigEndian]
    // B. The data used for testing.
    let headers = _TestData.headers
    let content = _TestData.content
    let input = [_TestData.headers] + _TestData.content
    // C. The actual operation testing.
    let work: (_ configuration: CSVWriter.Configuration, _ sample: String) throws -> Void = {
      let resultA = try CSVWriter.encode(rows: content, into: String.self, configuration: $0)
      XCTAssertTrue(resultA == $1)
      let resultB = try CSVWriter.encode(rows: content, into: Data.self, configuration: $0)
      guard let stringB = String(data: resultB, encoding: $0.encoding!) else { return XCTFail("Unable to encode Data into String") }
      XCTAssertTrue(resultA == stringB)
      let url = _TestData.generateTemporaryFileURL()
      try CSVWriter.encode(rows: content, into: url, configuration: $0)
      let resultC = try Data(contentsOf: url)
      guard let stringC = String(data: resultC, encoding: $0.encoding!) else { return XCTFail("Unable to encode Data into String") }
      XCTAssertTrue(resultA == stringC)
      try FileManager.default.removeItem(at: url)
    }
    // 1. Iterate through all configuration values.
    for r in rowDelimiters {
      for f in fieldDelimiters {
        let pair: Delimiter.Pair = (f, r)
        // 2. Generate the data for the given configuration values.
        let sample = _TestData.toCSV(input, delimiters: pair)

        for escaping in escapingStrategy {
          for encoding in encodings {
            var c = CSVWriter.Configuration()
            c.delimiters = pair
            c.escapingStrategy = escaping
            c.headers = headers
            c.encoding = encoding
            c.bomStrategy = .never
            // 3. Launch the actual test.
            try work(c, sample)
          }
        }
      }
    }
  }

  /// Tests the manual usages of `CSVWriter`.
  func testManualMemoryWriting() throws {
    // B. The data used for testing.
    let headers = _TestData.headers
    let content = _TestData.content
    let input = [_TestData.headers] + _TestData.content

    let writer = try CSVWriter { $0.headers = headers; $0.delimiters = (",", "\n"); $0.encoding = .utf8 }
    try content[0].forEach { try writer.write(field: $0) }
    try writer.endRow()

    try writer.write(fields: content[1])
    try writer.endRow()

    try writer.write(fields: content[2].dropLast())
    try writer.write(field: content[2].last!)
    try writer.endRow()

    for row in content[3...] {
      try writer.write(row: row)
    }

    try writer.endEncoding()

    let result = try writer.data()
    let data = _TestData.toCSV(input, delimiters: (",", "\n")).data(using: .utf8)!
    XCTAssertTrue(result.elementsEqual(data))
  }

  /// Tests the file creation capabilities of `CSVWriter`.
  func testFileCreation() throws {
    let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent(UUID().uuidString)
    let writer = try CSVWriter(fileURL: fileURL, append: false)
    try writer.write(row: ["one", "two", "three"])
    try writer.write(fields: ["four", "five", "six"])
    try writer.endRow()
    try writer.endEncoding()
    try FileManager.default.removeItem(at: fileURL)
  }

  /// Tests writing more fields that the ones being expected.
  func testFieldsOverflow() throws {
    let writer = try CSVWriter()
    try writer.write(row: ["one", "two", "three"])
    do {
      try writer.write(fields: ["four", "five", "six", "seven"])
      XCTFail("The previous line shall throw an error")
    } catch {
      try writer.endEncoding()
    }
  }

  /// Tests writing empty rows.
  func testEmptyRows() throws {
    let writer = try CSVWriter { $0.headers = ["One", "Two", "Three"] }
    try writer.writeEmptyRow()
    try writer.write(row: ["four", "five", "six"])
    try writer.writeEmptyRow()
    try writer.endEncoding()
  }

  /// Tests writing empty rows when the number of fields are unknown.
  func testUnkwnonEmptyRow() throws {
    let writer = try CSVWriter()
    do {
      try writer.writeEmptyRow()
      XCTFail("The previous line shall throw an error")
    } catch {
      try writer.endEncoding()
    }
  }
}
