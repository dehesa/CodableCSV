import XCTest
import CodableCSV

/// Tests checking the regular encoding usage.
final class EncodingOptionalsTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension EncodingOptionalsTests {
  /// Tests writting `nil` values on a keyed containers with named coding keys.
  func testOptionalNamedFields() throws {
    struct Student: Encodable {
      let name: String, age: Int?, country: String?, hasPet: Bool?
    }

    let students: [Student] = [
      Student(name: "Marcos", age: 1, country: "Spain", hasPet: true),
      Student(name: "Anaïs",  age: nil, country: "France", hasPet: false),
      Student(name: "Alex",   age: 3, country: nil, hasPet: false),
      Student(name: "家豪",    age: nil, country: "China", hasPet: nil),
      Student(name: "Дэниел", age: 5, country: nil, hasPet: nil),
      Student(name: "ももこ",  age: nil, country: nil, hasPet: nil)
    ]

    let encoder = CSVEncoder { $0.headers = ["name", "age", "country", "hasPet"] }
    let result = try encoder.encode(students, into: String.self)
    XCTAssertFalse(result.isEmpty)
  }

  /// Tests writting `nil` values on a keyed containers with integer coding keys.
  func testOptionalIntegerFields() throws {
    struct Student: Encodable {
      let name: String, age: Int?, country: String?, hasPet: Bool?
      private enum CodingKeys: Int, CodingKey {
        case name=0, age, country, hasPet
      }
    }

    let students: [Student] = [
      Student(name: "Marcos", age: 1, country: "Spain", hasPet: true),
      Student(name: "Anaïs",  age: nil, country: "France", hasPet: false),
      Student(name: "Alex",   age: 3, country: nil, hasPet: false),
      Student(name: "家豪",    age: nil, country: "China", hasPet: nil),
      Student(name: "Дэниел", age: 5, country: nil, hasPet: nil),
      Student(name: "ももこ",  age: nil, country: nil, hasPet: nil)
    ]

    let encoder = CSVEncoder()
    let result = try encoder.encode(students, into: String.self)
    XCTAssertFalse(result.isEmpty)
    XCTAssertTrue(result.hasPrefix("Marcos,1,Spain,true\nAnaïs,,France,false"))
  }

  /// Tests writting `nil` values on a keyed containers with named coding keys.
  func testOptionalNamedFieldsWithCustomStrategy() throws {
    struct Student: Encodable {
      let name: String, age: Int?, country: String?, hasPet: Bool?
    }

    let students: [Student] = [
      Student(name: "Marcos", age: 1, country: "Spain", hasPet: true),
      Student(name: "Anaïs",  age: nil, country: "France", hasPet: false),
      Student(name: "Alex",   age: 3, country: nil, hasPet: false),
      Student(name: "家豪",    age: nil, country: "China", hasPet: nil),
      Student(name: "Дэниел", age: 5, country: nil, hasPet: nil),
      Student(name: "ももこ",  age: nil, country: nil, hasPet: nil)
    ]

    let encoder = CSVEncoder {
      $0.headers = ["name", "age", "country", "hasPet"]
      $0.nilStrategy = .custom({
        var container = $0.singleValueContainer()
        try container.encode("null")
      })
    }
    let result = try encoder.encode(students, into: String.self)
    XCTAssertFalse(result.isEmpty)
    XCTAssertTrue(result.contains("null"))
  }
}
