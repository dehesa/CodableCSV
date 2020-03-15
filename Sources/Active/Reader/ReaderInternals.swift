import Foundation

extension CSVReader {
    /// Reader status indicating whether there are remaning lines to read, the CSV has been completely parsed, or an error occurred and no further operation shall be performed.
    public enum Status {
        /// The CSV file hasn't been completely parsed.
        case reading
        /// There are no more rows to read. The EOF has been reached.
        case finished
        /// An error has occurred and no further operations shall be performed with the reader instance.
        case failed(CSVReader.Error)
    }
}

extension CSVReader {
    /// Creates a reader instance that will be used to parse the given `String`.
    /// - parameter string: A `String` containing CSV formatted data.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(string: String, configuration: (inout Configuration)->Void) throws {
        var config = Configuration()
        configuration(&config)
        try self.init(string: string, configuration: config)
    }
    
    /// Creates a reader instance that will be used to parse the given data blob.
    /// - parameter data: A data blob containing CSV formatted data.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(data: Data, configuration: (inout Configuration)->Void) throws {
        var config = Configuration()
        configuration(&config)
        try self.init(data: data, configuration: config)
    }
    
    /// Creates a reader instance that will be used to parse the given CSV file.
    /// - parameter fileURL: The URL indicating the location of the file to be parsed.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(fileURL: URL, configuration: (inout Configuration)->Void) throws {
        var config = Configuration()
        configuration(&config)
        try self.init(fileURL: fileURL, configuration: config)
    }
}

extension CSVReader {
    /// Reads the Swift String and returns the CSV headers (if any) and all the records.
    /// - parameter string: A `String` value containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVReader.Error` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    public static func parse(string: String, configuration: Configuration = .init()) throws -> (headers: [String], rows: [[String]]) {
        let reader = try CSVReader(string: string, configuration: configuration)
        
        var result: [[String]] = .init()
        while let row = try reader.parseRow() {
            result.append(row)
        }
        
        return (reader.headers, result)
    }
    
    /// Reads a blob of data using the encoding provided as argument and returns the CSV headers (if any) and all the CSV records.
    /// - parameter data: A blob of data containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVReader.Error` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    public static func parse(data: Data, configuration: Configuration = .init()) throws -> (headers: [String], rows: [[String]]) {
        let reader = try CSVReader(data: data, configuration: configuration)
        
        var result: [[String]] = .init()
        while let row = try reader.parseRow() {
            result.append(row)
        }
        
        return (reader.headers, result)
    }
    
    /// Reads a CSV file using the provided encoding and returns the CSV headers (if any) and all the CSV records.
    /// - parameter fileURL: The URL indicating the location of the file to be parsed.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVReader.Error` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    public static func parse(fileURL: URL, configuration: Configuration = .init()) throws -> (headers: [String], rows: [[String]]) {
        let reader = try CSVReader(fileURL: fileURL, configuration: configuration)
        
        var result: [[String]] = .init()
        while let row = try reader.parseRow() {
            result.append(row)
        }
        
        return (reader.headers, result)
    }
}

extension CSVReader {
    /// Reads the Swift String and returns the CSV headers (if any) and all the records.
    /// - parameter string: A `String` value containing CSV formatted data.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVReader.Error` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    public static func parse(string: String, configuration: (inout Configuration)->Void) throws -> (headers: [String], rows: [[String]]) {
        var config = Configuration()
        configuration(&config)
        return try parse(string: string, configuration: config)
    }
    
    /// Reads a blob of data using the encoding provided as argument and returns the CSV headers (if any) and all the CSV records.
    /// - parameter data: A blob of data containing CSV formatted data.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVReader.Error` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    public static func parse(data: Data, configuration: (inout Configuration)->Void) throws -> (headers: [String], rows: [[String]]) {
        var config = Configuration()
        configuration(&config)
        return try parse(data: data, configuration: config)
    }
    
    /// Reads a CSV file using the provided encoding and returns the CSV headers (if any) and all the CSV records.
    /// - parameter fileURL: The URL indicating the location of the file to be parsed.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVReader.Error` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    public static func parse(fileURL: URL, configuration: (inout Configuration)->Void) throws -> (headers: [String], rows: [[String]]) {
        var config = Configuration()
        configuration(&config)
        return try parse(fileURL: fileURL, configuration: config)
    }
}
