import XCTest
import CodableCSV

/// Tests for the decodable car dealer data.
final class DecodingWrappersTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension DecodingWrappersTests {
  /// Data used throughout this test case referencing a list of cars.
  private enum _TestData {
    /// The column names for the CSV.
    static let headers: [String] = [
      "sequence", "name", "doors", "retractibleRoof", "fuel"
    ]
    /// List of pets available in the pet store.
    static let content: [[String]] = [
      ["0" , "Bolt"      , "2", "true" , "100"],
      ["1" , "Knockout"  , "3", "false", "10" ],
      ["2" , "Burner"    , "4", "false", "50" ],
      ["3" , "Pacer"     , "5", "true" , "330"],
      ["4" , "Blink"     , "2", "false", "222"],
      ["5" , "Scorch"    , "4", "true" , "177"],
      ["6" , "Furiosa"   , "2", "false", "532"],
      ["7" , "Hannibal"  , "5", "false", "29" ],
      ["8" , "Bam Bam"   , "5", "true" , "73" ],
      ["9" , "Snap"      , "3", "true" , "88" ],
      ["10", "Zinger"    , "2", "false", "43" ],
      ["11", "Screech"   , "4", "false", "278"],
      ["12", "Brimstone" , "5", "true" , "94" ],
      ["13", "Dust Devil", "5", "false", "64" ]
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

  /// Representation of a CSV row.
  fileprivate struct _Car: Decodable {
    let sequence: UInt
    let name: String
    let doors: UInt8
    let retractibleRoof: Bool
    let fuel: Fuel

    struct Fuel: Decodable {
      let value: Int16
      init(from decoder: Decoder) throws { self.value = try decoder.singleValueContainer().decode(Int16.self) }
    }
  }
}

// MARK: -

extension DecodingWrappersTests {
  /// Tests the list of cars (without any Decodable functionality).
  func testInputData() throws {
    // The configuration values to be tested.
    let encoding: String.Encoding = .utf8
    let delimiters: Delimiter.Pair = (",", "\n")
    // The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    let input = _TestData.toCSV([headers] + content, delimiters: delimiters)

    let parsed = try CSVReader.decode(input: input) {
      $0.encoding = encoding
      $0.delimiters = delimiters
      $0.headerStrategy = .firstLine
    }
    XCTAssertEqual(parsed.headers, _TestData.headers)
    XCTAssertEqual(parsed.rows, _TestData.content)
  }

  /// Test a simple regular usage where the test data is synthesized.
  func testRegularUsage() throws {
    // The configuration values to be tested.
    let delimiters: Delimiter.Pair = (",", "\n")
    let encoding: String.Encoding = .utf8
    let strategies: [Strategy.DecodingBuffer] = [.keepAll, .sequential]
    // The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    let input = _TestData.toCSV([headers] + content, delimiters: delimiters).data(using: encoding)!

    for s in strategies {
      let decoder = CSVDecoder {
        $0.encoding = encoding
        $0.delimiters = delimiters
        $0.headerStrategy = .firstLine
        $0.bufferingStrategy = s
      }

      let values = try decoder.decode([_Car].self, from: input)
      XCTAssertEqual(_TestData.content.count, values.count)
      XCTAssertEqual(_TestData.content, values.map { [String($0.sequence), $0.name, String($0.doors), String($0.retractibleRoof), String($0.fuel.value)] })
    }
  }

  /// Test unkeyed container and different usage of `superDecoder` and `decoder`.
  func testDecoderReuse() throws {
    // The configuration values to be tested.
    let delimiters: Delimiter.Pair = (",", "\n")
    let encoding: String.Encoding = .utf8
    let strategies: [Strategy.DecodingBuffer] = [.keepAll, .sequential]
    // The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    let input = _TestData.toCSV([headers] + content, delimiters: delimiters).data(using: encoding)!

    struct Custom: Decodable {
      let wrapper: Wrapper
      var remaining: [_Car] = []

      init(from decoder: Decoder) throws {
        var containerA = try decoder.unkeyedContainer()
        XCTAssertEqual(containerA.currentIndex, 0)
        for _ in 0..<Wrapper.Keys.allCases.first!.rawValue {
          self.remaining.append(try containerA.decode(_Car.self))
        }
        self.wrapper = try decoder.singleValueContainer().decode(Wrapper.self)
        let containerB = try decoder.unkeyedContainer()
        XCTAssertEqual(containerB.currentIndex, 0)
      }
    }

    struct Wrapper: Decodable {
      var values: [_Car] = []

      init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        for key in Keys.allCases {
          self.values.append(try container.decode(_Car.self, forKey: key))
        }
        XCTAssertEqual(self.values.count, Keys.allCases.count)
      }

      enum Keys: Int, CodingKey, CaseIterable { case a = 5, b, c, d, e }
    }

    for s in strategies {
      let decoder = CSVDecoder {
        $0.encoding = encoding
        $0.delimiters = delimiters
        $0.headerStrategy = .firstLine
        $0.bufferingStrategy = s
      }

      let instance = try decoder.decode(Custom.self, from: input)
      XCTAssertEqual(instance.wrapper.values.count, Wrapper.Keys.allCases.count)
      XCTAssertEqual(instance.wrapper.values.map { Int($0.sequence) }, Wrapper.Keys.allCases.map { $0.rawValue })
    }
  }

  /// Tests an unnecessary amount of single value containers wrapping.
  func testMatroska() throws {
    // The configuration values to be tested.
    let delimiters: Delimiter.Pair = (",", "\n")
    let encoding: String.Encoding = .utf8
    let strategies: [Strategy.DecodingBuffer] = [.keepAll, .sequential]
    // The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    let input = _TestData.toCSV([headers] + content, delimiters: delimiters).data(using: encoding)!

    struct Wrapper<W>: Decodable where W:Decodable {
      let next: W
      init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.next = try container.decode(W.self)
      }
    }

    struct Value: Decodable {
      let cars: [_Car]
      init(from decoder: Decoder) throws {
        self.cars = try decoder.singleValueContainer().decode([_Car].self)
      }
    }

    for s in strategies {
      let decoder = CSVDecoder {
        $0.encoding = encoding
        $0.delimiters = delimiters
        $0.headerStrategy = .firstLine
        $0.bufferingStrategy = s
      }
      let wrapper = try decoder.decode(Wrapper<Wrapper<Wrapper<Wrapper<Value>>>>.self, from: input)
      let values = wrapper.next.next.next.next.cars
      XCTAssertEqual(values.count, content.count)
    }
  }
}
