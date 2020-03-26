import XCTest
@testable import CodableCSV

/// Tests for empty or single value CSVs.
final class DecodingSinglesTests: XCTestCase {
    override func setUp() {
        self.continueAfterFailure = false
    }
}

// MARK: -

extension DecodingSinglesTests {
    /// Tests the decoding of a completely empty file.
    func testEmptyFile() throws {
        let decoder = CSVDecoder { $0.headerStrategy = .none }

        struct Custom: Decodable {
            init(from decoder: Decoder) throws {
                let unkeyedContainer = try decoder.unkeyedContainer()
                XCTAssertTrue(unkeyedContainer.isAtEnd)
                let keyedContainer = try decoder.container(keyedBy: DecodingKey.self)
                XCTAssertFalse(keyedContainer.contains(DecodingKey(0)))
                let _ = try decoder.singleValueContainer()
            }
        }

        let data = "".data(using: .utf8)!
        let _ = try decoder.decode(Custom.self, from: data)
    }

    /// Tests the decoding of file containing a single row with only one value.
    ///
    /// The custom decoding process will request an unkeyed container.
    func testSingleValueFileWithUnkeyedContainer() throws {
        let rowDelimiter: Delimiter.Row = "\n"
        let decoder = CSVDecoder {
            $0.delimiters.row = rowDelimiter
            $0.headerStrategy = .none
        }

        struct Custom: Decodable {
            let value: String

            init(from decoder: Decoder) throws {
                var fileContainer = try decoder.unkeyedContainer()
                self.value = try fileContainer.decode(String.self)
                XCTAssertTrue(fileContainer.isAtEnd)
            }
        }

        let data = ("Grumpy" + String(rowDelimiter.rawValue)).data(using: .utf8)!
        let _ = try decoder.decode(Custom.self, from: data)
    }

    /// Tests the decoding of file containing a single row with only one value.
    ///
    /// The custom decoding process will request an keyed container.
    func testSingleValueFileWithKeyedContainer() throws {
        let rowDelimiter: Delimiter.Row = "\n"
        let decoder = CSVDecoder {
            $0.encoding = .utf8
            $0.delimiters.row = rowDelimiter
            $0.headerStrategy = .none
        }

        struct Custom: Decodable {
            let value: Int32

            init(from decoder: Decoder) throws {
                let fileContainer = try decoder.container(keyedBy: CodingKeys.self)
                self.value = try fileContainer.decode(Int32.self, forKey: .value)
            }

            private enum CodingKeys: Int, CodingKey {
                case value = 0
            }
        }

        let data = ("34" + String(rowDelimiter.rawValue)).data(using: .utf8)!
        let _ = try decoder.decode(Custom.self, from: data)
    }

    /// Tests the decoding of file containing a single row with only one value.
    ///
    /// The custom decoding process will request a single value container.
    func testSingleValueFileWithValueContainer() throws {
        let rowDelimiter: Delimiter.Row = "\n"
        let decoder = CSVDecoder {
            $0.delimiters.row = rowDelimiter
            $0.headerStrategy = .none
        }

        struct Custom: Decodable {
            let value: UInt32

            init(from decoder: Decoder) throws {
                let wrapperContainer = try decoder.singleValueContainer()
                self.value = try wrapperContainer.decode(UInt32.self)
            }
        }

        let data = ("77" + String(rowDelimiter.rawValue)).data(using: .utf8)!
        let _ = try decoder.decode(Custom.self, from: data)
    }

    /// Tests the decoding of a file containing a single row with many values.
    ///
    /// The custom decoding process will request a unkeyed container.
    func testSingleRowFile() throws {
        let rowDelimiter: Delimiter.Row = "\n"
        let decoder = CSVDecoder {
            $0.delimiters.row = rowDelimiter
            $0.headerStrategy = .none
        }

        struct Custom: Decodable {
            private(set) var values: [Int8] = []

            init(from decoder: Decoder) throws {
                var fileContainer = try decoder.unkeyedContainer()
                while !fileContainer.isAtEnd {
                    values.append(try fileContainer.decode(Int8.self))
                }
            }
        }

        let data = (0...10).map { String($0) }
            .joined(separator: String(rowDelimiter.rawValue))
            .data(using: .utf8)!
        let _ = try decoder.decode(Custom.self, from: data)
    }

    /// Tests the decoding of a file containing a single row with many values.
    ///
    /// The custom decoding process will request unkeyed containers and manual decoding.
    func testSingleValueRowsWithkeyedContainer() throws {
        let rowDelimiter: Delimiter.Row = "\n"
        let decoder = CSVDecoder {
            $0.delimiters.row = rowDelimiter
            $0.headerStrategy = .none
        }

        struct Custom: Decodable {
            private(set) var values: [Int8] = []

            init(from decoder: Decoder) throws {
                var fileContainer = try decoder.unkeyedContainer()
                while !fileContainer.isAtEnd {
                    var rowContainer = try fileContainer.nestedUnkeyedContainer()
                    while !rowContainer.isAtEnd {
                        values.append(try rowContainer.decode(Int8.self))
                    }
                }
            }
        }

        let data = (0...10).map { String($0) }
            .joined(separator: String(rowDelimiter.rawValue))
            .data(using: .utf8)!
        let _ = try decoder.decode(Custom.self, from: data)
    }
}
