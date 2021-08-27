import XCTest
import CodableCSV

/// Tests checking the lazy encoding operation.
final class EncodingLazyTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension EncodingLazyTests {
  /// Test data used throughout this `XCTestCase`.
  private enum _TestData {
    struct KeyedStudent: Encodable {
      var name: String
      var age: Int
      var country: String
      var hasPet: Bool
    }

    struct UnkeyedStudent: Encodable {
      var name: String
      var age: Int
      var country: String
      var hasPet: Bool

      func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.name)
        try container.encode(self.age)
        try container.encode(self.country)
        try container.encode(self.hasPet)
      }
    }
  }
}

// MARK: -

extension EncodingLazyTests {
  /// Test the encoding of an empty CSV file.
  func testEmptyFile() throws {
    // The configuration values to be tests.
    let encoding: String.Encoding = .utf8
    let bomStrategy: Strategy.BOM = .never
    let delimiters: Delimiter.Pair = (",", "\n")
    let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll, .assembled, .sequential]

    for s in bufferStrategies {
      var configuration = CSVEncoder.Configuration()
      configuration.encoding = encoding
      configuration.bomStrategy = bomStrategy
      configuration.delimiters = delimiters
      configuration.bufferingStrategy = s

      let lazyEncoder = try CSVEncoder(configuration: configuration).lazy(into: Data.self)
      let data = try lazyEncoder.endEncoding()
      XCTAssertTrue(data.isEmpty)
    }
  }

  /// Tests the encoding of a single empty field in a CSV file.
  func testSingleEmptyField() throws {
    // The configuration values to be tests.
    let encoding: String.Encoding = .utf8
    let bomStrategy: Strategy.BOM = .never
    let delimiters: Delimiter.Pair = (",", "\n")
    let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll, .assembled, .sequential]
    // The data used for testing.
    let value = [String()]

    for s in bufferStrategies {
      var configuration = CSVEncoder.Configuration()
      configuration.encoding = encoding
      configuration.bomStrategy = bomStrategy
      configuration.delimiters = delimiters
      configuration.bufferingStrategy = s

      let lazyEncoder = try CSVEncoder(configuration: configuration).lazy(into: String.self)
      try lazyEncoder.encodeRow(value)
      let string = try lazyEncoder.endEncoding()
      XCTAssertEqual(string, "\(delimiters.row)")
    }
  }

  /// Tests a single custom type encoding (with headers).
  func testSingleCustomType() throws {
    // The configuration values to be tests.
    let encoding: String.Encoding = .utf8
    let bomStrategy: Strategy.BOM = .never
    let delimiters: Delimiter.Pair = (",", "\n")
    let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll, .assembled, .sequential]
    let headers = ["name", "age", "country", "hasPet"]
    // The data used for testing.
    let student = _TestData.KeyedStudent(name: "Marcos", age: 111, country: "Spain", hasPet: true)

    for s in bufferStrategies {
      var configuration = CSVEncoder.Configuration()
      configuration.encoding = encoding
      configuration.bomStrategy = bomStrategy
      configuration.delimiters = delimiters
      configuration.bufferingStrategy = s
      configuration.headers = headers

      let lazyEncoder = try CSVEncoder(configuration: configuration).lazy(into: String.self)
      try lazyEncoder.encodeRow(student)
      let string = try lazyEncoder.endEncoding()
      let content = string.split(separator: delimiters.row.description.first!)

      let encodedHeaders = content[0].split(separator: delimiters.field.description.first!).map { String($0) }
      XCTAssertEqual(headers, encodedHeaders)

      let encodedValues = content[1].split(separator: delimiters.field.description.first!).map { String($0) }
      XCTAssertEqual(student.name, encodedValues[0])
      XCTAssertEqual(String(student.age), encodedValues[1])
      XCTAssertEqual(String(student.country), encodedValues[2])
      XCTAssertEqual(String(student.hasPet), encodedValues[3])
    }
  }

  /// Tests a single custom type encoding (with NO headers).
  func testSingleCustomTypeNoHeaders() throws {
    // The configuration values to be tests.
    let encoding: String.Encoding = .utf8
    let bomStrategy: Strategy.BOM = .never
    let delimiters: Delimiter.Pair = (",", "\n")
    let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll, .assembled, .sequential]
    let headers: [String] = []
    // The data used for testing.
    let student = _TestData.UnkeyedStudent(name: "Marcos", age: 111, country: "Spain", hasPet: true)

    for s in bufferStrategies {
      var configuration = CSVEncoder.Configuration()
      configuration.encoding = encoding
      configuration.bomStrategy = bomStrategy
      configuration.delimiters = delimiters
      configuration.bufferingStrategy = s
      configuration.headers = headers

      let lazyEncoder = try CSVEncoder(configuration: configuration).lazy(into: String.self)
      try lazyEncoder.encodeRow(student)
      let string = try lazyEncoder.endEncoding()
      let content = string.split(separator: delimiters.row.description.first!)

      let encodedValues = content[0].split(separator: delimiters.field.description.first!).map { String($0) }
      XCTAssertEqual(student.name, encodedValues[0])
      XCTAssertEqual(String(student.age), encodedValues[1])
      XCTAssertEqual(String(student.country), encodedValues[2])
      XCTAssertEqual(String(student.hasPet), encodedValues[3])
    }
  }

  /// Tests multiple custom types encoding.
  func testMultipleKeyed() throws {
    // The configuration values to be tests.
    let encoding: String.Encoding = .utf8
    let bomStrategy: Strategy.BOM = .never
    let delimiters: Delimiter.Pair = (",", "\n")
    let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll, .assembled, .sequential]
    let headers = ["name", "age", "country", "hasPet"]
    // The data used for testing.
    typealias Student = _TestData.KeyedStudent
    let students: [Student] = [
      Student(name: "Marcos", age: 1, country: "Spain", hasPet: true),
      Student(name: "Anaïs",  age: 2, country: "France", hasPet: false),
      Student(name: "Alex",   age: 3, country: "Canada", hasPet: false),
      Student(name: "家豪",    age: 4, country: "China", hasPet: true),
      Student(name: "Дэниел", age: 5, country: "Russia", hasPet: true),
      Student(name: "ももこ",  age: 6, country: "Japan", hasPet: false)
    ]

    for s in bufferStrategies {
      let encoder = CSVEncoder()
      encoder.encoding = encoding
      encoder.bomStrategy = bomStrategy
      encoder.delimiters = delimiters
      encoder.bufferingStrategy = s
      encoder.headers = headers

      let lazyEncoder = try encoder.lazy(into: String.self)
      for student in students {
        try lazyEncoder.encodeRow(student)
      }

      let string = try lazyEncoder.endEncoding()
      let content = string.split(separator: delimiters.row.description.first!).map { String($0) }
      XCTAssertEqual(content.count, 1+students.count)
      XCTAssertEqual(content[0], headers.joined(separator: delimiters.field.description))
    }
  }

  /// Tests multiple custom types encoding (with headers).
  func testMultipleUnkeyed() throws {
    // The configuration values to be tests.
    let encoding: String.Encoding = .utf8
    let bomStrategy: Strategy.BOM = .never
    let delimiters: Delimiter.Pair = (",", "\n")
    let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll, .assembled, .sequential]
    let headers = [[], ["name", "age", "country", "hasPet"]]
    // The data used for testing.
    typealias Student = _TestData.UnkeyedStudent
    let students: [Student] = [
      Student(name: "Marcos", age: 1, country: "Spain", hasPet: true),
      Student(name: "Anaïs",  age: 2, country: "France", hasPet: false),
      Student(name: "Alex",   age: 3, country: "Canada", hasPet: false),
      Student(name: "家豪",    age: 4, country: "China", hasPet: true),
      Student(name: "Дэниел", age: 5, country: "Russia", hasPet: true),
      Student(name: "ももこ",  age: 6, country: "Japan", hasPet: false)
    ]

    for s in bufferStrategies {
      for h in headers {
        let encoder = CSVEncoder()
        encoder.encoding = encoding
        encoder.bomStrategy = bomStrategy
        encoder.delimiters = delimiters
        encoder.bufferingStrategy = s
        encoder.headers = h

        let lazyEncoder = try encoder.lazy(into: String.self)
        for student in students {
          try lazyEncoder.encodeRow(student)
        }
        let string = try lazyEncoder.endEncoding()
        XCTAssertFalse(string.isEmpty)

        let content = string.split(separator: delimiters.row.description.first!).map { String($0) }
        if h.isEmpty {
          XCTAssertEqual(content.count, students.count)
        } else {
          XCTAssertEqual(content.count, 1+students.count)
          XCTAssertEqual(content[0], h.joined(separator: delimiters.field.description))
        }
      }
    }
  }

  /// Tests multiple custom types encoding (with headers).
  func testEncodingEmptyRows() throws {
    // The configuration values to be tests.
    let encoding: String.Encoding = .utf8
    let bomStrategy: Strategy.BOM = .never
    let delimiters: Delimiter.Pair = (",", "\n")
    let bufferStrategies: [Strategy.EncodingBuffer] = [/*.keepAll, .assembled, */.sequential]
    let headers = [[], ["name", "age", "country", "hasPet"]]
    // The data used for testing.
    typealias Student = _TestData.UnkeyedStudent
    let studentsA: [Student] = [
      Student(name: "Marcos", age: 1, country: "Spain", hasPet: true),
      Student(name: "Anaïs",  age: 2, country: "France", hasPet: false)
    ]

    let studentsB: [Student] = [
      Student(name: "Alex",   age: 3, country: "Canada", hasPet: false),
      Student(name: "家豪",    age: 4, country: "China", hasPet: true),
      Student(name: "Дэниел", age: 5, country: "Russia", hasPet: true),
      Student(name: "ももこ",  age: 6, country: "Japan", hasPet: false)
    ]

    for s in bufferStrategies {
      for h in headers {
        let encoder = CSVEncoder()
        encoder.encoding = encoding
        encoder.bomStrategy = bomStrategy
        encoder.delimiters = delimiters
        encoder.bufferingStrategy = s
        encoder.headers = h

        let lazyEncoder = try encoder.lazy(into: String.self)
        for student in studentsA {
          try lazyEncoder.encodeRow(student)
        }
        try lazyEncoder.encodeEmptyRow()
        for student in studentsB {
          try lazyEncoder.encodeRow(student)
        }

        let string = try lazyEncoder.endEncoding()
        XCTAssertFalse(string.isEmpty)

        print(string)
      }
    }
  }
}
