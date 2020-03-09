import XCTest
@testable import CodableCSV

/// Tests for the decodable pet store data.
final class DecodingPetStoreTests: XCTestCase {
    // List of all tests to run through SPM.
    static let allTests = [
        ("testStoreData", testStoreData),
        ("testPets", testPets),
        ("testUnkeyedStore", testUnkeyedStore),
        ("testKeyedStore", testKeyedStore),
        ("testSuperDecoder", testSuperDecoder)
    ]
        
    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension DecodingPetStoreTests {
    /// Test data used throughout this `XCTestCase`.
    private enum TestData {
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
        /// Configuration used to generated the CSV data.
        static let configuration = CSVDecoder.Configuration(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headerStrategy: .firstLine)
        /// String version of the test data.
        static let string: String = ([header] + array).toCSV(delimiters: configuration.delimiters)
        /// Data version of the test data.
        static let blob: Data = ([header] + array).toCSV(delimiters: configuration.delimiters)!
    }

    /// Tests the list of pets (without any Decodable functionality).
    func testStoreData() throws {
        let parsed = try CSVReader.parse(string: TestData.string, configuration: TestData.configuration.readerConfiguration)
        XCTAssertNotNil(parsed.headers)
        XCTAssertEqual(parsed.headers!, TestData.header)
        XCTAssertEqual(parsed.rows, TestData.array)
    }
}

extension DecodingPetStoreTests {
    /// Description of a CSV row.
    private struct Pet: Decodable {
        let sequence: Int
        let name: String
        let age: Double
        let gender: Gender?
        let animal: String
        let isMammal: Bool
        
        enum Gender: String, Decodable {
            case masculine, feminine
        }
    }
    
    /// Decodes the list of animals into a list of pets (with no further decodable description more than its definition).
    func testPets() throws {
        let decoder = CSVDecoder(configuration: TestData.configuration)
        let pets = try decoder.decode([Pet].self, from: TestData.blob, encoding: .utf8)

        for (index, pet) in pets.enumerated() {
            let testPet = TestData.array[index]
            XCTAssertEqual(pet.sequence, Int(testPet[0])!)
            XCTAssertEqual(pet.name, testPet[1])
            XCTAssertEqual(pet.age, Double(testPet[2])!)
            XCTAssertEqual(pet.gender?.rawValue ?? "", testPet[3])
            XCTAssertEqual(pet.animal, testPet[4])
        }
    }
}

extension DecodingPetStoreTests {
    /// Decodable instance that exclusively uses unkeyed containers for decoding.
    private struct UnkeyedStore: Decodable {
        let pets: [[String]]
        
        init(from decoder: Decoder) throws {
            var pets: [[String]] = []
            
            var file = try decoder.unkeyedContainer()
            while !file.isAtEnd {
                var pet: [String] = []
                var record = try file.nestedUnkeyedContainer()
                while !record.isAtEnd {
                    pet.append(try record.decode(String.self))
                }
                pets.append(pet)
            }
            
            self.pets = pets
        }
    }
    
    /// Decodes the list of animals using nested unkeyed containers.
    func testUnkeyedStore() throws {
        let decoder = CSVDecoder(configuration: TestData.configuration)
        let store = try decoder.decode(UnkeyedStore.self, from: TestData.blob, encoding: .utf8)
        XCTAssertEqual(store.pets, TestData.array)
    }
}

extension DecodingPetStoreTests {
    /// Decodable instance that exclusively uses keyed containers for decoding.
    private struct KeyedStore: Decodable {
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
            case dog = 0
            case snake = 1
            case cat = 2
            case bird = 3
            case hamster = 4
            case bacteria = 5
        }
        
        private enum Property: String, CodingKey {
            case name
            case isMammal
        }
    }
    
    /// Decodes the list of animals using nested keyed containers.
    func testKeyedStore() throws {
        let decoder = CSVDecoder(configuration: TestData.configuration)
        let store = try decoder.decode(KeyedStore.self, from: TestData.blob, encoding: .utf8)
        XCTAssertEqual(store.mammals, TestData.array.filter { $0[5] == "true" }.map { $0[1] })
    }
}

extension DecodingPetStoreTests {
    private struct SuperStore: Decodable {
        let snake: Snake
        let bird: Bird
        
        init(from decoder: Decoder) throws {
            let file = try decoder.container(keyedBy: Specie.self)
            self.snake = try file.decode(Snake.self, forKey: .snake)
            self.bird = try file.decode(Bird.self, forKey: .bird)
        }
        
        class Animal: Decodable {
            let name: String
            let age: Double
        }
        
        final class Snake: Animal {
            let number: Int
            
            required init(from decoder: Decoder) throws {
                let row = try decoder.container(keyedBy: CodingKeys.self)
                self.number = try row.decode(Int.self, forKey: .number)
                try super.init(from: row.superDecoder())
            }
            
            private enum CodingKeys: String, CodingKey {
                case number = "sequence"
            }
        }
        
        final class Bird: Animal {
            let gender: Gender
            
            required init(from decoder: Decoder) throws {
                let row = try decoder.container(keyedBy: CodingKeys.self)
                self.gender = try row.decode(Gender.self, forKey: .gender)
                try super.init(from: row.superDecoder())
            }
            
            private enum CodingKeys: String, CodingKey {
                case gender
            }
            
            enum Gender: String, Decodable {
                case masculine
                case feminine
            }
        }
    }
    
    private enum Specie: Int, CodingKey, CaseIterable {
        case snake = 1
        case bird = 3
    }
    
    /// Test the decoder's `superDecoder()` calls (commonly used when subclassing).
    func testSuperDecoder() throws {
        let decoder = CSVDecoder(configuration: TestData.configuration)
        let store = try decoder.decode(SuperStore.self, from: TestData.blob, encoding: .utf8)
        XCTAssertEqual(store.snake.number, Specie.snake.rawValue)
        XCTAssertEqual(store.bird.gender, .feminine)
    }
}
