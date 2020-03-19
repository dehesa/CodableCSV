import XCTest
@testable import CodableCSV

/// Tests for the decodable car dealer data.
final class DecodingWrappersTests: XCTestCase {
    /// List of all tests to run through SPM.
    static let allTests = [
        ("testInputData", testInputData),
        ("testRegularUsage", testRegularUsage),
        ("testDecoderReuse", testDecoderReuse),
        ("testMatroska", testMatroska)
    ]

    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension DecodingWrappersTests {
    /// Data used throughout this test case referencing a list of cars.
    private enum Input {
        /// The column names for the CSV.
        static let header: [String] = [
            "sequence", "name", "doors", "retractibleRoof", "fuel"
        ]
        /// List of pets available in the pet store.
        static let array: [[String]] = [
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
        /// String version of the test data.
        static var string: String { ([header] + array).toCSV(delimiters: (",", "\n")) }
        /// Data version of the test data.
        static var blob: Data { ([header] + array).toCSV(delimiters: (",", "\n")) }
    }

    /// Representation of a CSV row.
    fileprivate struct Car: Decodable {
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

extension DecodingWrappersTests {
    /// Tests the list of cars (without any Decodable functionality).
    func testInputData() throws {
        let parsed = try CSVReader.parse(string: Input.string) { $0.headerStrategy = .firstLine }
        XCTAssertEqual(parsed.headers, Input.header)
        XCTAssertEqual(parsed.rows, Input.array)
    }

    /// Test a simple regular usage where the test data is synthesized.
    func testRegularUsage() throws {
        let decoder = CSVDecoder {
            $0.delimiters = (field: ",", row: "\n")
            $0.headerStrategy = .firstLine
        }
        
        let values = try decoder.decode([Car].self, from: Input.blob)
        XCTAssertEqual(Input.array.count, values.count)
        XCTAssertEqual(Input.array, values.map { [String($0.sequence), $0.name, String($0.doors), String($0.retractibleRoof), String($0.fuel.value)] })
    }

    /// Test unkeyed container and different usage of `superDecoder` and `decoder`.
    func testDecoderReuse() throws {
        let decoder = CSVDecoder {
            $0.delimiters = (field: ",", row: "\n")
            $0.headerStrategy = .firstLine
        }

        struct Custom: Decodable {
            let wrapper: Wrapper
            var remaining: [Car] = []

            init(from decoder: Decoder) throws {
                var containerA = try decoder.unkeyedContainer()
                XCTAssertEqual(containerA.currentIndex, 0)
                for _ in 0..<Wrapper.Keys.allCases.first!.rawValue {
                    self.remaining.append(try containerA.decode(Car.self))
                }
                self.wrapper = try decoder.singleValueContainer().decode(Wrapper.self)
                let containerB = try decoder.unkeyedContainer()
                XCTAssertEqual(containerB.currentIndex, 0)
            }
        }

        struct Wrapper: Decodable {
            var values: [Car] = []

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: Keys.self)
                for key in Keys.allCases {
                    self.values.append(try container.decode(Car.self, forKey: key))
                }
                XCTAssertEqual(self.values.count, Keys.allCases.count)
            }

            enum Keys: Int, CodingKey, CaseIterable { case a = 5, b, c, d, e }
        }

        let instance = try decoder.decode(Custom.self, from: Input.blob)
        XCTAssertEqual(instance.wrapper.values.count, Wrapper.Keys.allCases.count)
        XCTAssertEqual(instance.wrapper.values.map { Int($0.sequence) }, Wrapper.Keys.allCases.map { $0.rawValue })
    }

    /// Tests an unnecessary amount of single value containers wrapping.
    func testMatroska() throws {
        let decoder = CSVDecoder {
            $0.delimiters = (field: ",", row: "\n")
            $0.headerStrategy = .firstLine
        }

        struct Wrapper<W>: Decodable where W:Decodable {
            let next: W
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                self.next = try container.decode(W.self)
            }
        }

        struct Value: Decodable {
            let cars: [Car]
            init(from decoder: Decoder) throws {
                self.cars = try decoder.singleValueContainer().decode([Car].self)
            }
        }

        let wrapper = try decoder.decode(Wrapper<Wrapper<Wrapper<Wrapper<Value>>>>.self, from: Input.blob)
        let values = wrapper.next.next.next.next.cars
        XCTAssertEqual(values.count, Input.array.count)
    }
}
