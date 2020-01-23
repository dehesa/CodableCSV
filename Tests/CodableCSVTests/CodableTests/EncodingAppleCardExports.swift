import CodableCSV
import XCTest

/// Tests for the encodable Apple Card data.
final class EncodingAppleCardTests: XCTestCase {
    // List of all tests to run through SPM.
    static let allTests = [
        ("testTransactions", testTransactions)
    ]
    
    override func setUp() {
        self.continueAfterFailure = false
    }
}

extension EncodingAppleCardTests {
    /// Test data used throughout this `XCTestCase`.
    private enum TestData {
        /// The column names for the CSV.
        static let header: [String] = ["transactionDate", "clearingDate", "description", "merchant", "category", "type", "amount"]
        /// List of transactions.
        static let array: [[String]] = [
            ["10/04/2019", "10/04/2019", "Merchant A on Main Street",                          "Merchant A",      "Restaurants", "Purchase", "10.70"   ],
            ["09/31/2019", "09/31/2019", "A Payment",                                          "The Bank",        "Other",       "Payment",  "-340.54" ],
            ["09/24/2019", "09/24/2019", "Apple ONE APPLE PARK WAY 866-712-7753 95014 CA USA", "Apple Services",  "Other",       "Purchase", "14.68"   ],
            ["09/17/2019", "09/17/2019", "Apple ONE APPLE PARK WAY 866-712-7753 95014 CA USA", "Apple Services",  "Other",       "Purchase", "53.49"   ],
            ["09/05/2019", "09/06/2019", "Full On Artwork",                                    "Full On Artwork", "Other",       "Purchase", "100.02"  ],
            ["09/01/2019", "09/01/2019", "Seafood by the Bay",                                 "Salty's",         "Restaurants", "Purchase", "98.32"   ]
        ]
        /// Configuration used to generated the CSV data.
        static let decoderConfiguration = DecoderConfiguration(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headerStrategy: .firstLine)
        /// Configuration used to read the CSV data.
        static let encoderConfiguration = EncoderConfiguration(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headers: TestData.header)
        /// String version of the test data.
        static let string: String = ([header] + array).toCSV(delimiters: decoderConfiguration.delimiters)
        /// Data version of the test data.
        static let blob: Data = ([header] + array).toCSV(delimiters: decoderConfiguration.delimiters)!
    }
}

extension EncodingAppleCardTests {
    /// Description of a CSV row.
    private struct Transaction: Codable {
        let transactionDate: String
        let clearingDate: String
        let description: String
        let merchant: String
        let category: String
        let type: String
        var amount: String
  
        init(from decoder: Decoder) throws {
            var row = try decoder.unkeyedContainer()
            self.transactionDate = try row.decode(String.self)
            self.clearingDate = try row.decode(String.self)
            self.description = try row.decode(String.self)
            self.merchant = try row.decode(String.self)
            self.category = try row.decode(String.self)
            self.type = try row.decode(String.self)
            self.amount = try row.decode(String.self)
         }

        func encode(to encoder: Encoder) throws {
            var row = encoder.unkeyedContainer()
            try row.encode(self.transactionDate)
            try row.encode(self.clearingDate)
            try row.encode(self.description)
            try row.encode(self.merchant)
            try row.encode(self.category)
            try row.encode(self.type)
            try row.encode(self.amount)
        }

    }
    
    /// Decodes the list of transactions
    /// then encodes them
    func testTransactions() throws {
        let decoder = CSVDecoder(configuration: TestData.decoderConfiguration)
        let transactions = try decoder.decode([Transaction].self, from: TestData.blob, encoding: .utf8)
        
        for (index, transaction) in transactions.enumerated() {
            let testTransaction = TestData.array[index]
            XCTAssertEqual(transaction.transactionDate, testTransaction[0])
            XCTAssertEqual(transaction.clearingDate, testTransaction[1])
            XCTAssertEqual(transaction.description, testTransaction[2])
            XCTAssertEqual(transaction.merchant, testTransaction[3])
            XCTAssertEqual(transaction.category, testTransaction[4])
            XCTAssertEqual(transaction.type, testTransaction[5])
            XCTAssertEqual(transaction.amount, testTransaction[6])
        }
                
        let encoder = CSVEncoder(configuration: TestData.encoderConfiguration)
        let encodedTransactions = try encoder.encode(transactions)
        
        let decodedTransactions = try decoder.decode([Transaction].self, from: encodedTransactions, encoding: .utf8)

        for (index, transaction) in decodedTransactions.enumerated() {
             let testTransaction = TestData.array[index]
             XCTAssertEqual(transaction.transactionDate, testTransaction[0])
             XCTAssertEqual(transaction.clearingDate, testTransaction[1])
             XCTAssertEqual(transaction.description, testTransaction[2])
             XCTAssertEqual(transaction.merchant, testTransaction[3])
             XCTAssertEqual(transaction.category, testTransaction[4])
             XCTAssertEqual(transaction.type, testTransaction[5])
             XCTAssertEqual(transaction.amount, testTransaction[6])
         }

    }
}
