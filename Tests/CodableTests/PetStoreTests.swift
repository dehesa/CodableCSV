import XCTest
@testable import CSV

/// Tests for the decodable school data tests.
final class PetStoreTests: XCTestCase {
    /// CSV data listing a bunch of animals.
    private let csv: (string: String, configuration: CSV.Configuration) = ("""
    sequence,name,age,gender,animal,isMammal
    0,Rocky,3.2,masculine,dog,true
    1,Slissy,4.7,feminine,snake,false
    2,Grumpy,0.5,masculine,cat,true
    3,Adele,1.3,feminine,bird,false
    4,Chum,0.2,feminine,hamster,true
    5,Bacterio,999.9,,bacteria,false
    """, .init(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headerStrategy: .firstLine, trimStrategy: .none))

    /// Tests the list of pets (without any Decodable functionality) and parse it into an array of strings.
    func testStoreData() {
        do {
            let (headers, rows) = try CSVReader.parse(string: self.csv.string, configuration: self.csv.configuration)
            XCTAssertNotNil(headers)
            XCTAssertEqual(headers!.count, 6)
            XCTAssertFalse(rows.isEmpty)
        } catch let error {
            XCTFail("The following error was not expected:\n\(error)")
        }
    }
}

extension PetStoreTests {
    /// Decodes the list of animals into a list of pets (with no further decodable description more than its definition).
    func testPets() {
        let decoder = CSVDecoder(configuration: csv.configuration)
        
        do {
            let data = self.csv.string.data(using: .utf8)!
            let pets = try decoder.decode([Pet].self, from: data, encoding: .utf8)
            XCTAssertFalse(pets.isEmpty)
        } catch let error {
            XCTFail("The following error was not expected:\n\(error)")
        }
    }
    
    /// Description of a CSV row.
    private struct Pet: Decodable {
        let sequence: Int
        let name: String
        let age: Double
        let gender: Gender?
        let animal: String
        let isMammal: Bool
        
        enum Gender: String, Decodable {
            case masculine
            case feminine
        }
    }
}

extension PetStoreTests {
    /// Decodes the list of animals using nested unkeyed containers.
    func testUnkeyedStore() {
        let decoder = CSVDecoder(configuration: csv.configuration)
        
        do {
            let data = self.csv.string.data(using: .utf8)!
            let store = try decoder.decode(UnkeyedStore.self, from: data, encoding: .utf8)
            XCTAssertFalse(store.pets.isEmpty)
        } catch let error {
            XCTFail("The following error was not expected:\n\(error)")
        }
    }
    
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
}

extension PetStoreTests {
    /// Decodes the list of animals using nested keyed containers.
    func testKeyedStore() {
        let decoder = CSVDecoder(configuration: csv.configuration)
        
        do {
            let store = try decoder.decode(keyedStore.self, from: self.csv.string.data(using: .utf8)!, encoding: .utf8)
            XCTAssertFalse(store.mammals.isEmpty)
            XCTAssertEqual(store.mammals.count, 3)
        } catch let error {
            XCTFail("The following error was not expected:\n\(error)")
        }
    }
    
    /// Decodable instance that exclusively uses keyed containers for decoding.
    private struct keyedStore: Decodable {
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
        }
        
        private enum Property: String, CodingKey {
            case name
            case isMammal
        }
    }
}

extension PetStoreTests {
    /// Test the superDecoder calls usually used in class hierarchy.
    func testSuperDecoder() {
        let decoder = CSVDecoder(configuration: csv.configuration)
        
        do {
            let store = try decoder.decode(SuperStore.self, from: self.csv.string.data(using: .utf8)!, encoding: .utf8)
            XCTAssertEqual(store.snake.number, Specie.snake.rawValue)
            XCTAssertEqual(store.bird.gender, .feminine)
        } catch let error {
            XCTFail("The following error was not expected:\n\(error)")
        }
    }
    
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
}
