import XCTest
@testable import CodableCSV

/// Tests generic and edge cases from a CSV reader perspective.
final class ReaderTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension ReaderTests {
  /// The test data used for this file.
  private enum _TestData {
    /// A CSV row representing a header row (4 fields).
    static let headers   =  ["seq", "Name", "Country", "Number Pair"]
    /// Small amount of regular CSV rows (4 fields per row).
    static let content  =  [["1", "Marcos", "Spain", "99"],
                            ["2", "Marine-Anaïs", "France", "88"],
                            ["3", "Alex", "Germany", "77"],
                            ["4", "Pei", "China", "66"]]
    /// A bunch of rows each one containing an edge case.
    static let edgeCases = [["", "Marcos", "Spaiñ", "99"],
                            ["2", "Marine-Anaïs", #""Fra""nce""#, ""],
                            ["", "", "", ""],
                            ["4", "Pei", "China", #""\#n""#],
                            ["", "", "", #""\#r\#n""#],
                            ["5", #""A\#rh,me\#nd""#, "Egypt", #""\#r""#],
                            ["6", #""Man""olo""#, "México", "100_000"]]
    /// Exactly the same data as `contentEdgeCases`, but the quotes delimiting the beginning and end of a field have been removed.
    ///
    /// It is tipically used to check the result of parsing `contentEdgeCases`.
    static let unescapedEdgeCases = [
      ["", "Marcos", "Spaiñ", "99"],
      ["2", "Marine-Anaïs", #"Fra"nce"#, ""],
      ["", "", "", ""],
      ["4", "Pei", "China", "\n"],
      ["", "", "", "\r\n"],
      ["5", "A\rh,me\nd", "Egypt", "\r"],
      ["6", #"Man"olo"#, "México", "100_000"]]
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

  private typealias _Encoded = (string: String, data: Data, url: URL)
}

// MARK: -

extension ReaderTests {
  /// Tests the correct parsing of an empty CSV.
  func testEmpty() throws {
    // A. The configuration values to be tested.
    var config = CSVReader.Configuration()
    config.headerStrategy = .none
    // 1. Tests the full-file string decoder.
    let fileFromString = try CSVReader.decode(input: "", configuration: config)
    XCTAssertTrue(fileFromString.headers.isEmpty)
    XCTAssertTrue(fileFromString.rows.isEmpty)
    // 2. Tests the full-file data decoder.
    let fileFromData = try CSVReader.decode(input: Data(), configuration: config)
    XCTAssertTrue(fileFromData.headers.isEmpty)
    XCTAssertTrue(fileFromData.rows.isEmpty)
    // 3. Tests the full-file decoder.
    let url = _TestData.generateTemporaryFileURL()
    XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: Data()))
    let fileFromFile = try CSVReader.decode(input: url, configuration: config)
    XCTAssertTrue(fileFromFile.headers.isEmpty)
    XCTAssertTrue(fileFromFile.rows.isEmpty)
    try FileManager.default.removeItem(at: url)
    // 4. Tests the line reader.
    let reader = try CSVReader(input: "", configuration: config)
    XCTAssertTrue(reader.headers.isEmpty)
    XCTAssertNil(try reader.readRow())
    XCTAssertEqual(reader.rowIndex, 0)
  }

  /// Tests the correct parsing of a single CSV field.
  func testSingleField() throws {
    // A. The configuration values to be tested.
    var config = CSVReader.Configuration()
    config.delimiters = (",", "\n")
    config.headerStrategy = .none
    // B. The data used for testing.
    let input = [["Marine-Anaïs"]]
    let string = _TestData.toCSV(input, delimiters: config.delimiters)
    let data = string.data(using: .utf8)!
    // 1. Tests the full-file string decoder.
    let fileFromString = try CSVReader.decode(input: string, configuration: config)
    XCTAssertTrue(fileFromString.headers.isEmpty)
    XCTAssertEqual(fileFromString.rows, input)
    // 2. Tests the full-file data decoder.
    let fileFromData = try CSVReader.decode(input: data, configuration: config)
    XCTAssertTrue(fileFromData.headers.isEmpty)
    XCTAssertEqual(fileFromData.rows, input)
    // 3. Tests the full-file decoder.
    let url = _TestData.generateTemporaryFileURL()
    XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: data))
    let fileFromFile = try CSVReader.decode(input: url, configuration: config)
    XCTAssertTrue(fileFromFile.headers.isEmpty)
    XCTAssertEqual(fileFromFile.rows, input)
    try FileManager.default.removeItem(at: url)
    // 4. Tests the line reader.
    let reader = try CSVReader(input: string, configuration: config)
    XCTAssertTrue(reader.headers.isEmpty)
    XCTAssertEqual(input[0], try reader.readRow()!)
    XCTAssertNil(try reader.readRow())
  }

  /// Tests a small generic CSV (with and without headers).
  func testRegularUsage() throws {
    // A. The configuration values to be tested.
    let rowDelimiters: [Delimiter.Row] = ["\n", "\r", "\r\n", "**~**"]
    let fieldDelimiters: [Delimiter.Field] = [",", ";", "\t", "|", "||", "|-|"]
    let headerStrategy: [Strategy.Header] = [.none, .firstLine]
    let trimStrategy = [CharacterSet(), .whitespaces]
    let escapingStrategy: [Strategy.Escaping] = [.none, .doubleQuote]
    let presamples: [Bool] = [true, false]
    // B. The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    // C. The actual operation testing.
    let work: (_ configuration: CSVReader.Configuration, _ encoded: _Encoded) throws -> Void = {
      let resultA = try CSVReader.decode(input: $1.string, configuration: $0)
      let resultB = try CSVReader.decode(input: $1.data, configuration: $0)
      let resultC = try CSVReader.decode(input: $1.url, configuration: $0)

      if $0.headerStrategy == .none {
        XCTAssertTrue(resultA.headers.isEmpty)
        XCTAssertTrue(resultB.headers.isEmpty)
        XCTAssertTrue(resultC.headers.isEmpty)
      } else {
        XCTAssertFalse(resultA.headers.isEmpty)
        XCTAssertEqual(resultA.headers, headers)
        XCTAssertEqual(resultA.headers, resultB.headers)
        XCTAssertEqual(resultA.headers, resultC.headers)
      }

      XCTAssertEqual(resultA.rows, content)
      XCTAssertEqual(resultB.rows, content)
      XCTAssertEqual(resultC.rows, content)
    }

    // Iterate through all configuration values.
    for r in rowDelimiters {
      for f in fieldDelimiters {
        let pair: Delimiter.Pair = (f, r)

        for h in headerStrategy {
          let input: [[String]]
          switch h {
          case .none: input = content
          case .firstLine: input = [headers] + content
          }
          // 2. Generate the data for the given configuration values.
          let string = _TestData.toCSV(input, delimiters: pair)
          let data = string.data(using: .utf8)!
          let url = _TestData.generateTemporaryFileURL()
          XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: data))
          let encoded: _Encoded = (string, data, url)

          for t in trimStrategy {
            var toTrim = t
            if f.scalars.count == 1, t.contains(f.scalars.first!) { toTrim.remove(f.scalars.first!) }
            if r.scalars.first!.count == 1, t.contains(r.scalars.first!.first!) { toTrim.remove(r.scalars.first!.first!) }

            for e in escapingStrategy {
              for p in presamples {
                var c = CSVReader.Configuration()
                c.delimiters = pair
                c.headerStrategy = h
                c.trimStrategy = toTrim
                c.escapingStrategy = e
                c.presample = p
                // 3. Launch the actual test.
                try work(c, encoded)
              }
            }
          }

          try FileManager.default.removeItem(at: url)
        }
      }
    }
  }

  /// Tests a set of edge cases data.
  ///
  /// Some edge cases are, for example, the last row's field is empty or a row delimiter within quotes.
  func testEdgeCases() throws {
    // A. The configuration values to be tested.
    let rowDelimiters: [Delimiter.Row] = ["\n", "\r", "\r\n", "**~**"]
    let fieldDelimiters: [Delimiter.Field] = [",", ";", "\t", "|", "||", "|-|"]
    let headerStrategy: [Strategy.Header] = [.none, .firstLine]
    let trimStrategy = [CharacterSet(), /*.whitespaces*/] // The whitespaces remove the row or field delimiters.
    let presamples: [Bool] = [true, false]
    // B. The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.edgeCases)
    let unescapedContent = _TestData.unescapedEdgeCases
    // C. The actual operation testing.
    let work: (_ configuration: CSVReader.Configuration, _ encoded: _Encoded) throws -> Void = {
      let resultA = try CSVReader.decode(input: $1.string, configuration: $0)
      let resultB = try CSVReader.decode(input: $1.data, configuration: $0)
      let resultC = try CSVReader.decode(input: $1.url, configuration: $0)

      if $0.headerStrategy == .none {
        XCTAssertTrue(resultA.headers.isEmpty)
        XCTAssertTrue(resultB.headers.isEmpty)
        XCTAssertTrue(resultC.headers.isEmpty)
      } else {
        XCTAssertFalse(resultA.headers.isEmpty)
        XCTAssertEqual(resultA.headers, headers)
        XCTAssertEqual(resultA.headers, resultB.headers)
        XCTAssertEqual(resultA.headers, resultC.headers)
      }
      XCTAssertEqual(resultA.rows, unescapedContent, String(reflecting: $0))
      XCTAssertEqual(resultB.rows, unescapedContent, String(reflecting: $0))
    }
    // 1. Iterate through all configuration values.
    for r in rowDelimiters {
      for f in fieldDelimiters {
        let pair: Delimiter.Pair = (f, r)

        for h in headerStrategy {
          let input: [[String]]
          switch h {
          case .none: input = content
          case .firstLine: input = [headers] + content
          }
          // 2. Generate the data for the given configuration values.
          let string = _TestData.toCSV(input, delimiters: pair)
          let data = string.data(using: .utf8)!
          let url = _TestData.generateTemporaryFileURL()
          XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: data))
          let encoded: _Encoded = (string, data, url)

          for t in trimStrategy {
            var toTrim = t
            if f.scalars.count == 1, t.contains(f.scalars.first!) { toTrim.remove(f.scalars.first!) }
            if r.scalars.count == 1, t.contains(r.scalars.first!.first!) { toTrim.remove(r.scalars.first!.first!) }

            for p in presamples {
              var c = CSVReader.Configuration()
              c.delimiters = pair
              c.headerStrategy = h
              c.trimStrategy = toTrim
              c.presample = p
              // 3. Launch the actual test.
              try work(c, encoded)
            }
          }

          try FileManager.default.removeItem(at: url)
        }
      }
    }
  }

  /// Tests a small generic CSV with some of its fields quoted.
  /// - note: This test will randomly generate quoted fields from an unquoted set of data.
  func testQuotedFields() throws {
    // A. The configuration values to be tested.
    let rowDelimiters: [Delimiter.Row] = ["\n", "\r", "\r\n", "**~**"]
    let fieldDelimiters: [Delimiter.Field] = [",", ";", "\t", "|", "||", "|-|"]
    let trimStrategy = [CharacterSet(), .whitespaces]
    let presamples: [Bool] = [true, false]
    // B. The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    let input = ([headers] + content)._mappingRandomFields(count: 5) { [quote = Character("\"")] in
      guard !$0.hasPrefix(String(quote)) else { return $0 }

      var field = $0
      field.insert(quote, at: field.startIndex)
      field.append(quote)
      return field
    }
    // C. The actual operation testing.
    let work: (_ configuration: CSVReader.Configuration, _ encoded: _Encoded) throws -> Void = {
      let resultA = try CSVReader.decode(input: $1.string, configuration: $0)
      let resultB = try CSVReader.decode(input: $1.data, configuration: $0)
      let resultC = try CSVReader.decode(input: $1.url, configuration: $0)
      XCTAssertFalse(resultA.headers.isEmpty)
      XCTAssertEqual(resultA.headers, headers)
      XCTAssertEqual(resultA.headers, resultB.headers)
      XCTAssertEqual(resultA.headers, resultC.headers)
      XCTAssertEqual(resultA.rows, content)
      XCTAssertEqual(resultB.rows, content)
      XCTAssertEqual(resultC.rows, content)
    }

    // 1. Iterate through all configuration values.
    for r in rowDelimiters {
      for f in fieldDelimiters {
        let pair: Delimiter.Pair = (f, r)
        // 2. Generate the data for the given configuration values.
        let string = _TestData.toCSV(input, delimiters: pair)
        let data = string.data(using: .utf8)!
        let url = _TestData.generateTemporaryFileURL()
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: data))
        let encoded: _Encoded = (string, data, url)

        for t in trimStrategy {
          var toTrim = t
          if f.scalars.count == 1, t.contains(f.scalars.first!) { toTrim.remove(f.scalars.first!) }
          if r.scalars.count == 1, t.contains(r.scalars.first!.first!) { toTrim.remove(r.scalars.first!.first!) }

          for p in presamples {
            var c = CSVReader.Configuration()
            c.delimiters = pair
            c.headerStrategy = .firstLine
            c.trimStrategy = toTrim
            c.presample = p
            // 3. Launch the actual test.
            try work(c, encoded)
          }
        }

        try FileManager.default.removeItem(at: url)
      }
    }
  }

  /// Tests an invalid CSV input, which should lead to an error being thrown.
  /// - note: This test randomly generates invalid data every time is run.
  func testInvalidFieldCount() throws {
    // A. The configuration values to be tested.
    let rowDelimiters: [Delimiter.Row] = ["\n", "\r", "\r\n"]
    let fieldDelimiters: [Delimiter.Field] = [",", ";", "\t"]
    let presamples: [Bool] = [true, false]
    // B. The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    let input = ([headers] + content)._removingRandomFields(count: 2)
    // 1. Iterate through all configuration values.
    for r in rowDelimiters {
      for f in fieldDelimiters {
        let pair: Delimiter.Pair = (f, r)
        // 2. Generate the data for the given configuration values.
        let string = _TestData.toCSV(input, delimiters: pair)
        let data = string.data(using: .utf8)!
        let url = _TestData.generateTemporaryFileURL()
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: data))
        let encoded: _Encoded = (string, data, url)

        for p in presamples {
          var c = CSVReader.Configuration()
          c.delimiters = pair
          c.headerStrategy = .firstLine
          c.presample = p
          XCTAssertThrowsError(try CSVReader.decode(input: encoded.string, configuration: c))
          XCTAssertThrowsError(try CSVReader.decode(input: encoded.data, configuration: c))
          XCTAssertThrowsError(try CSVReader.decode(input: encoded.url, configuration: c))
        }

        try FileManager.default.removeItem(at: url)
      }
    }
  }
}

// MARK: -

fileprivate extension Array where Element == [String] {
  /// Removes a random field from a random row.
  /// - parameter num: The number of random fields to remove.
  mutating func _removeRandomFields(count: Int = 1) {
    guard !self.isEmpty && !self.first!.isEmpty else {
      fatalError("The receiving rows cannot be empty.")
    }

    for _ in 0..<count {
      let selectedRow = Int.random(in: 0..<self.count)
      let selectedField = Int.random(in: 0..<self[selectedRow].count)

      let _ = self[selectedRow].remove(at: selectedField)
    }
  }

  /// Copies the receiving array and removes from it a random field from a random row.
  /// - parameter num: The number of random fields to remove.
  /// - returns: A copy of the receiving array lacking `count` number of fields.
  func _removingRandomFields(count: Int = 1) -> [[String]] {
    var result = self
    result._removeRandomFields(count: count)
    return result
  }

  /// Transform a random field into the value returned in the argument closure.
  /// - parameter num: The number of random fields to modify.
  mutating func _mapRandomFields(count: Int = 1, _ transform: (String) -> String) {
    guard !self.isEmpty && !self.first!.isEmpty else {
      fatalError("The receiving rows cannot be empty.")
    }

    for _ in 0..<count {
      let selectedRow = Int.random(in: 0..<self.count)
      let selectedField = Int.random(in: 0..<self[selectedRow].count)

      self[selectedRow][selectedField] = transform(self[selectedRow][selectedField])
    }
  }

  /// Copies the receiving array and transforms a random field from it into another value.
  /// - parameter num: The number of random fields to modify.
  /// - returns: A copy of the receiving array with the `count` number of fields modified.
  func _mappingRandomFields(count: Int = 1, _ transform: (String) -> String) -> [[String]] {
    var result = self
    result._mapRandomFields(count: count, transform)
    return result
  }
}
