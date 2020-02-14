import CodableCSV
import Foundation

internal extension Array where Element == [String] {
    /// Encodes the test data into a Swift String.
    /// - parameters delimiters: Unicode scalars to use to mark fields and rows.
    /// - returns: Swift String representing the CSV file.
    func toCSV(delimiters: Delimiter.Pair = (.comma, .lineFeed)) -> String {
        return self.map { (row) in
            row.joined(separator: delimiters.field.stringValue!)
        }.joined(separator: delimiters.row.stringValue!) + delimiters.row.stringValue!
    }
    
    /// Encodes the test data into binary data with the given encoding.
    /// - parameter delimiters: Unicode scalars to use to mark fields and rows.
    func toCSV(delimiters: Delimiter.Pair = (.comma, .lineFeed)) -> Data? {
        let string: String = self.toCSV(delimiters: delimiters)
        return string.data(using: .utf8)
    }
}

internal extension Array where Element == [String] {
    /// Removes a random field from a random row.
    /// - parameter num: The number of random fields to remove.
    mutating func removeRandomFields(count: Int = 1) {
        guard !self.isEmpty && !self.first!.isEmpty else {
            fatalError("The receiving rows cannot be empty.")
        }
        
        for _ in 0..<count {
            let selectedRow = Int.random(in: 0..<self.count)
            let selectedField = Int.random(in: 0..<self[selectedRow].count)
            
            let _ = self[selectedRow].remove(at: selectedField)
        }
    }
    
    /// Copies the receiving array and removes from it a random field from a random row.
    /// - parameter num: The number of random fields to remove.
    /// - returns: A copy of the receiving array lacking `count` number of fields.
    func removingRandomFields(count: Int = 1) -> [[String]] {
        var result = self
        result.removeRandomFields(count: count)
        return result
    }
}

internal extension Array where Element == [String] {
    /// Transform a random field into the value returned in the argument closure.
    /// - parameter num: The number of random fields to modify.
    mutating func mapRandomFields(count: Int = 1, _ transform: (String) -> String) {
        guard !self.isEmpty && !self.first!.isEmpty else {
            fatalError("The receiving rows cannot be empty.")
        }
        
        for _ in 0..<count {
            let selectedRow = Int.random(in: 0..<self.count)
            let selectedField = Int.random(in: 0..<self[selectedRow].count)
            
            self[selectedRow][selectedField] = transform(self[selectedRow][selectedField])
        }
    }
    
    /// Copies the receiving array and transforms a random field from it into another value.
    /// - parameter num: The number of random fields to modify.
    /// - returns: A copy of the receiving array with the `count` number of fields modified.
    func mappingRandomFields(count: Int = 1, _ transform: (String) -> String) -> [[String]] {
        var result = self
        result.mapRandomFields(count: count, transform)
        return result
    }
}
