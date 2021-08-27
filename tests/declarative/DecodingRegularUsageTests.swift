import XCTest
import CodableCSV

/// Checks the regular decoding usage.
final class DecodingRegularUsageTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension DecodingRegularUsageTests {
  /// Test data used throughout this `XCTestCase`.
  private enum _TestData {
    /// The column names for the CSV.
    static let headers: [String] = ["sequence", "name", "age", "gender", "animal", "isMammal"]
    /// List of pets available in the pet store.
    static let content: [[String]] = [
      ["0", "Rocky"   , "3.2"  , "masculine", "dog"     , "true"    ],
      ["1", "Slissy"  , "4.7"  , "feminine" , "snake"   , "false"   ],
      ["2", "Grumpy"  , "0.5"  , "masculine", "cat"     , "true"    ],
      ["3", "Adele"   , "1.3"  , "feminine" , "bird"    , "false"   ],
      ["4", "Chum"    , "0.2"  , "feminine" , "hamster" , "true"    ],
      ["5", "Bacterio", "999.9", ""         , "bacteria", "false"   ]
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

// MARK: -

extension DecodingRegularUsageTests {
  /// Tests the input data (without any Decodable functionality).
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

  /// Decodes the list of animals into a list of pets (with no further decodable description more than its definition).
  func testSynthesizedInitializer() throws {
    // The configuration values to be tested.
    let delimiters: Delimiter.Pair = (",", "\n")
    let encoding: String.Encoding = .utf8
    let strategies: [Strategy.DecodingBuffer] = [.keepAll, .sequential]
    // The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    let input = _TestData.toCSV([headers] + content, delimiters: delimiters).data(using: encoding)!

    struct Pet: Decodable {
      let sequence: Int
      let name: String
      let age: Double
      let gender: Gender?
      let animal: String
      let isMammal: Bool
      enum Gender: String, Decodable { case masculine, feminine }
    }

    for s in strategies {
      let decoder = CSVDecoder {
        $0.encoding = encoding
        $0.delimiters = delimiters
        $0.headerStrategy = .firstLine
        $0.bufferingStrategy = s
      }

      let pets = try decoder.decode([Pet].self, from: input)
      for (index, pet) in pets.enumerated() {
        let testPet = _TestData.content[index]
        XCTAssertEqual(pet.sequence, Int(testPet[0])!)
        XCTAssertEqual(pet.name, testPet[1])
        XCTAssertEqual(pet.age, Double(testPet[2])!)
        XCTAssertEqual(pet.gender?.rawValue ?? "", testPet[3])
        XCTAssertEqual(pet.animal, testPet[4])
      }

      for (index, row) in try decoder.lazy(from: input).enumerated() {
        let pet = try row.decode(Pet.self)
        let testPet = _TestData.content[index]
        XCTAssertEqual(pet.sequence, Int(testPet[0])!)
        XCTAssertEqual(pet.name, testPet[1])
        XCTAssertEqual(pet.age, Double(testPet[2])!)
        XCTAssertEqual(pet.gender?.rawValue ?? "", testPet[3])
        XCTAssertEqual(pet.animal, testPet[4])
      }
    }
  }

  /// Decodes the list of animals using nested unkeyed containers.
  func testUnkeyedContainers() throws {
    // The configuration values to be tested.
    let delimiters: Delimiter.Pair = (",", "\n")
    let encoding: String.Encoding = .utf8
    let strategies: [Strategy.DecodingBuffer] = [.keepAll, .sequential]
    // The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    let input = _TestData.toCSV([headers] + content, delimiters: delimiters).data(using: encoding)!

    struct UnkeyedStore: Decodable {
      let pets: [[String]]

      init(from decoder: Decoder) throws {
        var pets: [[String]] = []

        var file = try decoder.unkeyedContainer()
        while !file.isAtEnd {
          var pet: [String] = []
          var record = try file.nestedUnkeyedContainer()
          while !record.isAtEnd { pet.append(try record.decode(String.self)) }
          pets.append(pet)
        }

        self.pets = pets
      }
    }

    for s in strategies {
      let decoder = CSVDecoder {
        $0.encoding = encoding
        $0.delimiters = delimiters
        $0.headerStrategy = .firstLine
        $0.bufferingStrategy = s
      }

      let store = try decoder.decode(UnkeyedStore.self, from: input)
      XCTAssertEqual(store.pets, _TestData.content)
    }
  }

  /// Decodes the list of animals using nested keyed containers.
  func testKeyedContainers() throws {
    // The configuration values to be tested.
    let delimiters: Delimiter.Pair = (",", "\n")
    let encoding: String.Encoding = .utf8
    let strategies: [Strategy.DecodingBuffer] = [.keepAll, .sequential]
    // The data used for testing.
    let (headers, content) = (_TestData.headers, _TestData.content)
    let input = _TestData.toCSV([headers] + content, delimiters: delimiters).data(using: encoding)!

    struct KeyedStore: Decodable {
      let mammals: [String]

      init(from decoder: Decoder) throws {
        var mammals: [String] = Array()

        let file = try decoder.container(keyedBy: _Animal.self)
        for key in _Animal.allCases {
          let row = try file.nestedContainer(keyedBy: _Property.self, forKey: key)
          guard try row.decode(Bool.self, forKey: .isMammal) else { continue }
          mammals.append(try row.decode(String.self, forKey: .name))
        }

        self.mammals = mammals
      }

      private enum _Animal: Int, CodingKey, CaseIterable {
        case dog = 0, snake, cat, bird, hamster, bacteria
      }

      private enum _Property: String, CodingKey {
        case name, isMammal
      }
    }

    for s in strategies {
      let decoder = CSVDecoder {
        $0.encoding = encoding
        $0.delimiters = delimiters
        $0.headerStrategy = .firstLine
        $0.bufferingStrategy = s
      }

      let store = try decoder.decode(KeyedStore.self, from: input)
      XCTAssertEqual(store.mammals, _TestData.content.filter { $0[5] == "true" }.map { $0[1] })
    }
  }
}
