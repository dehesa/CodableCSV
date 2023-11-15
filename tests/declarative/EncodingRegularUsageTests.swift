import XCTest
import CodableCSV

/// Tests checking the regular encoding usage.
final class EncodingRegularUsageTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension EncodingRegularUsageTests {
  /// Test data used throughout this `XCTestCase`.
  private enum _TestData {
    struct KeyedStudent: Encodable {
      var name: String
      var age: Int
      var country: String
      var hasPet: Bool
    }
      
    struct KeyedStudentCamelCaseTimeZone: Codable {
          var firstName: String
          var lastName: String
          var age: Int
          var countryOfStudy: String?
          var hasPet: Bool
          var timeZone: TimeZone
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

    struct School<S:Encodable>: Encodable {
      var students: [S]
      func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for student in self.students { try container.encode(student) }
      }
    }

    struct GapSchool<S:Encodable>: Encodable {
      var studentA: S
      var studentB: S
      var studentC: S
      var studentD: S
      var studentE: S
      var studentF: S

      init(students: [S]) {
        self.studentA = students[0]
        self.studentB = students[1]
        self.studentC = students[2]
        self.studentD = students[3]
        self.studentE = students[4]
        self.studentF = students[5]
      }

      enum CodingKeys: Int, CodingKey {
        case studentA = 0
        case studentB = 4
        case studentC = 5
        case studentD = 10
        case studentE = 20
        case studentF = 49
      }

      var lastIndex: Int { CodingKeys.studentF.rawValue }
    }
  }
}

// MARK: -

extension EncodingRegularUsageTests {
  /// Tests the encoding of an empty CSV file.
  func testEmptyFile() throws {
    // The configuration values to be tests.
    let encoding: String.Encoding = .utf8
    let bomStrategy: Strategy.BOM = .never
    let delimiters: Delimiter.Pair = (",", "\n")
    let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll, .assembled, .sequential]
    // The data used for testing.
    let value: [[String]] = []

    for s in bufferStrategies {
      var configuration = CSVEncoder.Configuration()
      configuration.encoding = encoding
      configuration.bomStrategy = bomStrategy
      configuration.delimiters = delimiters
      configuration.bufferingStrategy = s

      let encoder = CSVEncoder(configuration: configuration)
      let data = try encoder.encode(value, into: Data.self)
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
    let value = [[String()]]

    for s in bufferStrategies {
      var configuration = CSVEncoder.Configuration()
      configuration.encoding = encoding
      configuration.bomStrategy = bomStrategy
      configuration.delimiters = delimiters
      configuration.bufferingStrategy = s

      let encoder = CSVEncoder(configuration: configuration)
      let data = try encoder.encode(value, into: Data.self)
      let string = String(data: data, encoding: encoding)!
      XCTAssertEqual(string, "\(delimiters.row)")
    }
  }

  /// Tests the encoding of an empty custom type.
  func testEmptyCustomType() throws {
    // The configuration values to be tests.
    let encoding: String.Encoding = .utf8
    let bomStrategy: Strategy.BOM = .never
    let delimiters: Delimiter.Pair = (",", "\n")
    let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll, .assembled, .sequential]
    // The data used for testing.
    let school = _TestData.School<_TestData.KeyedStudent>(students: [])

    for s in bufferStrategies {
      var configuration = CSVEncoder.Configuration()
      configuration.encoding = encoding
      configuration.bomStrategy = bomStrategy
      configuration.delimiters = delimiters
      configuration.bufferingStrategy = s

      let encoder = CSVEncoder(configuration: configuration)
      let data = try encoder.encode(school, into: Data.self)
      XCTAssertTrue(data.isEmpty)
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
    let school = _TestData.School<_TestData.KeyedStudent>(students: [student])

    for s in bufferStrategies {
      var configuration = CSVEncoder.Configuration()
      configuration.encoding = encoding
      configuration.bomStrategy = bomStrategy
      configuration.delimiters = delimiters
      configuration.bufferingStrategy = s
      configuration.headers = headers

      let encoder = CSVEncoder(configuration: configuration)
      let string = try encoder.encode(school, into: String.self)
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
    let school = _TestData.School<_TestData.UnkeyedStudent>(students: [student])

    for s in bufferStrategies {
      var configuration = CSVEncoder.Configuration()
      configuration.encoding = encoding
      configuration.bomStrategy = bomStrategy
      configuration.delimiters = delimiters
      configuration.bufferingStrategy = s
      configuration.headers = headers

      let encoder = CSVEncoder(configuration: configuration)
      let string = try encoder.encode(school, into: String.self)
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
    let student: [Student] = [
      Student(name: "Marcos", age: 1, country: "Spain", hasPet: true),
      Student(name: "Anaïs",  age: 2, country: "France", hasPet: false),
      Student(name: "Alex",   age: 3, country: "Canada", hasPet: false),
      Student(name: "家豪",    age: 4, country: "China", hasPet: true),
      Student(name: "Дэниел", age: 5, country: "Russia", hasPet: true),
      Student(name: "ももこ",  age: 6, country: "Japan", hasPet: false)
    ]
    let school = _TestData.School<_TestData.KeyedStudent>(students: student)

    for s in bufferStrategies {
      let encoder = CSVEncoder()
      encoder.encoding = encoding
      encoder.bomStrategy = bomStrategy
      encoder.delimiters = delimiters
      encoder.bufferingStrategy = s
      encoder.headers = headers

      let string = try encoder.encode(school, into: String.self)
      let content = string.split(separator: delimiters.row.description.first!).map { String($0) }
      XCTAssertEqual(content.count, 1+student.count)
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
    let student: [Student] = [
      Student(name: "Marcos", age: 1, country: "Spain", hasPet: true),
      Student(name: "Anaïs",  age: 2, country: "France", hasPet: false),
      Student(name: "Alex",   age: 3, country: "Canada", hasPet: false),
      Student(name: "家豪",    age: 4, country: "China", hasPet: true),
      Student(name: "Дэниел", age: 5, country: "Russia", hasPet: true),
      Student(name: "ももこ",  age: 6, country: "Japan", hasPet: false)
    ]
    let school = _TestData.School<_TestData.UnkeyedStudent>(students: student)

    for s in bufferStrategies {
      for h in headers {
        let encoder = CSVEncoder()
        encoder.encoding = encoding
        encoder.bomStrategy = bomStrategy
        encoder.delimiters = delimiters
        encoder.bufferingStrategy = s
        encoder.headers = h

        let string = try encoder.encode(school, into: String.self)
        XCTAssertFalse(string.isEmpty)

        let content = string.split(separator: delimiters.row.description.first!).map { String($0) }
        if h.isEmpty {
          XCTAssertEqual(content.count, student.count)
        } else {
          XCTAssertEqual(content.count, 1+student.count)
          XCTAssertEqual(content[0], h.joined(separator: delimiters.field.description))
        }
      }
    }
  }

  /// Tests multiple custom type econding (
  func testGapsMultipleKeyed() throws {
    // The configuration values to be tests.
    let encoding: String.Encoding = .utf8
    let bomStrategy: Strategy.BOM = .never
    let delimiters: Delimiter.Pair = (",", "\n")
    let bufferStrategies: [Strategy.EncodingBuffer] = [.keepAll, .assembled, .sequential]
    let headers = [[], ["name", "age", "country", "hasPet"]]
    // The data used for testing.
    typealias Student = _TestData.UnkeyedStudent
    let school = _TestData.GapSchool(students: [
      Student(name: "Marcos", age: 1, country: "Spain", hasPet: true),
      Student(name: "Anaïs",  age: 2, country: "France", hasPet: false),
      Student(name: "Alex",   age: 3, country: "Canada", hasPet: false),
      Student(name: "家豪",    age: 4, country: "China", hasPet: true),
      Student(name: "Дэниел", age: 5, country: "Russia", hasPet: true),
      Student(name: "ももこ",  age: 6, country: "Japan", hasPet: false)
    ])

    for s in bufferStrategies {
      for h in headers {
        let encoder = CSVEncoder()
        encoder.encoding = encoding
        encoder.bomStrategy = bomStrategy
        encoder.delimiters = delimiters
        encoder.bufferingStrategy = s
        encoder.headers = h

        let string = try encoder.encode(school, into: String.self)
        XCTAssertFalse(string.isEmpty)

        let content = string.split(separator: delimiters.row.description.first!).map { String($0) }
        if h.isEmpty {
          XCTAssertEqual(content.count, school.lastIndex+1)
        } else {
          XCTAssertEqual(content.count, school.lastIndex+2)
          XCTAssertEqual(content[0], h.joined(separator: delimiters.field.description))
        }
      }
    }
  }
    
    /// Tests multiple custom types encoding.
  func testKeyEncodingStrategy() throws {
      // The configuration values to be tests.
      let encoding: String.Encoding = .utf8
      //let bomStrategy: Strategy.BOM = .never
      let delimiters: Delimiter.Pair = (",", "\n")
      let headers = ["name", "age", "country", "hasPet"]
      //The data used for testing.
      typealias Student = _TestData.KeyedStudentCamelCaseTimeZone
      let students: [Student] = [
        Student(firstName: "Marcos", lastName: "aaa", age: 1, countryOfStudy: "Spain", hasPet: true, timeZone: .init(abbreviation: "EST")!),
        Student(firstName: "Anaïs",  lastName: "bbb", age: 2, countryOfStudy: "France", hasPet: false, timeZone: .init(abbreviation: "PST")!),
        Student(firstName: "Alex",   lastName: "ccc", age: 3, countryOfStudy: nil, hasPet: false, timeZone: .init(abbreviation: "NST")!),
        Student(firstName: "家豪",    lastName: "ddd", age: 4, countryOfStudy: "China", hasPet: true, timeZone: .init(abbreviation: "AST")!),
        Student(firstName: "Дэниел", lastName: "eee", age: 5, countryOfStudy: "Russia", hasPet: true, timeZone: .init(abbreviation: "MST")!),
        Student(firstName: "ももこ",  lastName: "fff", age: 6, countryOfStudy: "Japan", hasPet: false, timeZone: .init(abbreviation: "CST")!)
      ]
      
      let jsonEncoder = JSONEncoder()
      let res = try jsonEncoder.encode(students)
      let rs = String(data: res, encoding: encoding)!
      print(rs)
      
      let encoder = CSVEncoder()
      //encoder.headers = headers
      encoder.encoding = encoding
      encoder.keyEncodingStrategy = .convertToSnakeCase
      encoder.timeZoneStrategy = .json
      encoder.delimiters = delimiters
      encoder.headerStrategy = .parseFromValue
      
      let string = try XCTUnwrap(try encoder.encode(students, into: String.self))
      let content = string.split(separator: delimiters.row.description.first!).map { String($0) }
      XCTAssertEqual(content.count, 1+students.count)
    }
    
    
}
