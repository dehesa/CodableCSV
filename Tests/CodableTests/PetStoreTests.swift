import XCTest
@testable import CSV

/// Tests for the decodable school data tests.
final class PetStoreTests: XCTestCase {
    
    /// The CSV data.
    private let csv: (string: String, configuration: CSV.Configuration) = ("""
    Sequence,Name,Age,Gender,Animal,"is Mammal"
    0,Rocky,3.2,masculine,dog,true
    1,Slissy,4.7,feminine,snake,false
    2,Grumpy,0.5,masculine,cat,true
    4,Adele,1.3,feminine,bird,false
    5,Chum,0.2,feminine,hamster,true
    6,Bacterio,999.9,,bacteria,false
    """, .init(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headerStrategy: .firstLine, trimStrategy: .none))

    func testData() {
        do {
            let (headers, rows) = try CSVReader.parse(string: self.csv.string, configuration: self.csv.configuration)
            XCTAssertNotNil(headers)
            XCTAssertEqual(headers!.count, 6)
            XCTAssertFalse(rows.isEmpty)
        } catch let error {
            XCTFail("The following error was not expected:\n\(error)")
        }
    }
    
    func testDecodable() {
        let decoder = CSVDecoder()
        decoder.delimiters = self.csv.configuration.delimiters
        decoder.headerStrategy = self.csv.configuration.strategies.header
        decoder.trimStrategy = self.csv.configuration.strategies.trim
        
        do {
            let store = try decoder.decode(GenericStore.self, from: self.csv.string.data(using: .utf8)!, encoding: .utf8)
            print(store)
            XCTAssertFalse(store.pets.isEmpty)
        } catch let error {
            XCTFail("The following error was not expected:\n\(error)")
        }
    }
}

fileprivate struct GenericStore: Decodable {
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
