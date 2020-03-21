import XCTest
@testable import CodableCSV

/// Tests for the decodable pet store data.
final class DecodingRegularUsageTests: XCTestCase {
    // List of all tests to run through SPM.
    static let allTests = [
        ("testInputData", testInputData),
        ("testSynthesizedInitializer", testSynthesizedInitializer),
        ("testUnkeyedContainers", testUnkeyedContainers),
        ("testKeyedContainers", testKeyedContainers)
    ]

    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension DecodingRegularUsageTests {
    /// Test data used throughout this `XCTestCase`.
    private enum Input {
        /// The column names for the CSV.
        static let header: [String] = ["sequence", "name", "age", "gender", "animal", "isMammal"]
        /// List of pets available in the pet store.
        static let array: [[String]] = [
            ["0", "Rocky"   , "3.2"  , "masculine", "dog"     , "true"    ],
            ["1", "Slissy"  , "4.7"  , "feminine" , "snake"   , "false"   ],
            ["2", "Grumpy"  , "0.5"  , "masculine", "cat"     , "true"    ],
            ["3", "Adele"   , "1.3"  , "feminine" , "bird"    , "false"   ],
            ["4", "Chum"    , "0.2"  , "feminine" , "hamster" , "true"    ],
            ["5", "Bacterio", "999.9", ""         , "bacteria", "false"   ]
        ]
        /// String version of the test data.
        static let string: String = ([header] + array).toCSV(delimiters: (",", "\n"))
        /// Data version of the test data.
        static let blob: Data = ([header] + array).toCSV(delimiters: (",", "\n"))
    }
}

extension DecodingRegularUsageTests {
    /// Tests the input data (without any Decodable functionality).
    func testInputData() throws {
        let parsed = try CSVReader.parse(input: Input.string) { $0.headerStrategy = .firstLine }
        XCTAssertEqual(parsed.headers, Input.header)
        XCTAssertEqual(parsed.rows, Input.array)
    }

    /// Decodes the list of animals into a list of pets (with no further decodable description more than its definition).
    func testSynthesizedInitializer() throws {
        let decoder = CSVDecoder {
            $0.delimiters = (field: ",", row: "\n")
            $0.headerStrategy = .firstLine
        }

        struct Pet: Decodable {
            let sequence: Int
            let name: String
            let age: Double
            let gender: Gender?
            let animal: String
            let isMammal: Bool
            enum Gender: String, Decodable { case masculine, feminine }
        }

        let pets = try decoder.decode([Pet].self, from: Input.blob)
        for (index, pet) in pets.enumerated() {
            let testPet = Input.array[index]
            XCTAssertEqual(pet.sequence, Int(testPet[0])!)
            XCTAssertEqual(pet.name, testPet[1])
            XCTAssertEqual(pet.age, Double(testPet[2])!)
            XCTAssertEqual(pet.gender?.rawValue ?? "", testPet[3])
            XCTAssertEqual(pet.animal, testPet[4])
        }
    }

    /// Decodes the list of animals using nested unkeyed containers.
    func testUnkeyedContainers() throws {
        let decoder = CSVDecoder {
            $0.delimiters = (field: ",", row: "\n")
            $0.headerStrategy = .firstLine
        }

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

        let store = try decoder.decode(UnkeyedStore.self, from: Input.blob)
        XCTAssertEqual(store.pets, Input.array)
    }

    /// Decodes the list of animals using nested keyed containers.
    func testKeyedContainers() throws {
        let decoder = CSVDecoder {
            $0.delimiters = (field: ",", row: "\n")
            $0.headerStrategy = .firstLine
        }

        struct KeyedStore: Decodable {
            let mammals: [String]

            init(from decoder: Decoder) throws {
                var mammals: [String] = .init()

                let file = try decoder.container(keyedBy: Specie.self)
                for key in Specie.allCases {
                    let row = try file.nestedContainer(keyedBy: Property.self, forKey: key)
                    guard try row.decode(Bool.self, forKey: .isMammal) else { continue }
                    mammals.append(try row.decode(String.self, forKey: .name))
                }

                self.mammals = mammals
            }

            private enum Specie: Int, CodingKey, CaseIterable {
                case dog = 0, snake, cat, bird, hamster, bacteria
            }

            private enum Property: String, CodingKey {
                case name, isMammal
            }
        }

        let store = try decoder.decode(KeyedStore.self, from: Input.blob)
        XCTAssertEqual(store.mammals, Input.array.filter { $0[5] == "true" }.map { $0[1] })
    }
}
