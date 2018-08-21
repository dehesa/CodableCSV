import Foundation

extension CSVReader {
    /// Creates a reader instance to go over a Swift String.
    /// - note: This method will have whole string in memory; thus, if the CSV is very big you may experience a loss in performance.
    /// - parameter string: A Swift String containing CSV formatted data.
    /// - parameter configuration: Generic explanation on how the CSV is formatted.
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(string: String, configuration: CSV.Configuration = .init()) throws {
        let iterator = string.unicodeScalars.makeIterator()
        try self.init(iterator: iterator, configuration: configuration)
    }
    
    /// Creates a reader instance to go over a blob of data.
    /// - note: This method will have the whole data blob in memory; thus, if the CSV is very big you may experience a loss in performance.
    /// - parameter data: A blob of data containing CSV formatted data.
    /// - parameter encoding: String encoding used to transform the data blob into text.
    /// - parameter configuration: Generic explanation on how the CSV is formatted.
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(data: Data, encoding: String.Encoding, configuration: CSV.Configuration = .init()) throws {
        guard let string = String(data: data, encoding: encoding) else {
            throw Error.invalidInput(message: "The data blob couldn't be encoded with the given encoding (rawValue: \(encoding.rawValue))")
        }
        try self.init(string: string, configuration: configuration)
    }
}

extension CSVReader {
    public typealias ParsingResult = (headers: [String]?, rows: [[String]])
    
    /// Reads the Swift String and returns the headers (if any) and all the rows.
    ///
    /// Parsing instead of relying on `Sequence` functionality (such as for..in.., map, etc.) will give you the benefit of throwing an error (and not crashing) when encountering a CSV format mistake.
    /// - note: This method will have whole string in memory; thus, if the CSV is very big you may experience a loss in performance.
    /// - parameter string: A Swift String containing CSV formatted data.
    /// - parameter configuration: Generic explanation on how the CSV is formatted.
    /// - throws: `CSVReader.Error` exclusively.
    public static func parse(string: String, configuration: CSV.Configuration = .init()) throws -> ParsingResult {
        let reader = try CSVReader(string: string, configuration: configuration)
        
        var result: [[String]] = .init()
        while let row = try reader.parseRow() {
            result.append(row)
        }
        
        return (reader.headers, result)
    }
    
    /// Reads a blob of data using the encoding provided as argument and returns the headers (if any) and all the rows.
    ///
    /// Parsing instead of relying on `Sequence` functionality (such as for..in.., map, etc.) will give you the benefit of throwing an error (and not crashing) when encountering a CSV format mistake.
    /// - note: This method will have the whole data blob in memory; thus, if the CSV is very big you may experience a loss in performance.
    /// - parameter data: A blob of data containing CSV formatted data.
    /// - parameter configuration: Generic explanation on how the CSV is formatted.
    /// - throws: `CSVReader.Error` exclusively.
    public static func parse(data: Data, encoding: String.Encoding, configuration: CSV.Configuration = .init()) throws -> ParsingResult {
        guard let string = String(data: data, encoding: encoding) else {
            throw Error.invalidInput(message: "The data blob couldn't be encoded with the given encoding (rawValue: \(encoding.rawValue))")
        }
        return try self.parse(string: string, configuration: configuration)
    }
}
