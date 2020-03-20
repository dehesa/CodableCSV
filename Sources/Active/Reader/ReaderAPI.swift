import Foundation

extension CSVReader {
    /// Creates a reader instance that will be used to parse the given `String`.
    /// - parameter string: A `String` containing CSV formatted data.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVError<CSVReader>` exclusively.
    @inlinable public convenience init(string: String, configuration: (inout Configuration)->Void) throws {
        var config = Configuration()
        configuration(&config)
        try self.init(string: string, configuration: config)
    }
    
    /// Creates a reader instance that will be used to parse the given data blob.
    /// - parameter data: A data blob containing CSV formatted data.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVError<CSVReader>` exclusively.
    @inlinable public convenience init(data: Data, configuration: (inout Configuration)->Void) throws {
        var config = Configuration()
        configuration(&config)
        try self.init(data: data, configuration: config)
    }
    
    /// Creates a reader instance that will be used to parse the given CSV file.
    /// - parameter fileURL: The URL indicating the location of the file to be parsed.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVError<CSVReader>` exclusively.
    @inlinable public convenience init(fileURL: URL, configuration: (inout Configuration)->Void) throws {
        var config = Configuration()
        configuration(&config)
        try self.init(fileURL: fileURL, configuration: config)
    }
}

extension CSVReader {
    /// Reads the Swift String and returns the CSV headers (if any) and all the records.
    /// - parameter string: A `String` value containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    public static func parse(string: String, configuration: Configuration = .init()) throws -> Output {
        let reader = try CSVReader(string: string, configuration: configuration)
        let lookup = try reader.makeHeaderLookup()
        
        var result: [[String]] = .init()
        while let row = try reader.parseRow() {
            result.append(row)
        }
        
        return .init(headers: reader.headers, rows: result, lookup: lookup)
    }
    
    /// Reads a blob of data using the encoding provided as argument and returns the CSV headers (if any) and all the CSV records.
    /// - parameter data: A blob of data containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    public static func parse(data: Data, configuration: Configuration = .init()) throws -> Output {
        let reader = try CSVReader(data: data, configuration: configuration)
        let lookup = try reader.makeHeaderLookup()
        
        var result: [[String]] = .init()
        while let row = try reader.parseRow() {
            result.append(row)
        }
        
        return .init(headers: reader.headers, rows: result, lookup: lookup)
    }
    
    /// Reads a CSV file using the provided encoding and returns the CSV headers (if any) and all the CSV records.
    /// - parameter fileURL: The URL indicating the location of the file to be parsed.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    public static func parse(fileURL: URL, configuration: Configuration = .init()) throws -> Output {
        let reader = try CSVReader(fileURL: fileURL, configuration: configuration)
        let lookup = try reader.makeHeaderLookup()
        
        var result: [[String]] = .init()
        while let row = try reader.parseRow() {
            result.append(row)
        }
        
        return .init(headers: reader.headers, rows: result, lookup: lookup)
    }
}

extension CSVReader {
    /// Reads the Swift String and returns the CSV headers (if any) and all the records.
    /// - parameter string: A `String` value containing CSV formatted data.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    @inlinable public static func parse(string: String, configuration: (inout Configuration)->Void) throws -> Output {
        var config = Configuration()
        configuration(&config)
        return try CSVReader.parse(string: string, configuration: config)
    }

    /// Reads a blob of data using the encoding provided as argument and returns the CSV headers (if any) and all the CSV records.
    /// - parameter data: A blob of data containing CSV formatted data.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    @inlinable public static func parse(data: Data, configuration: (inout Configuration)->Void) throws -> Output {
        var config = Configuration()
        configuration(&config)
        return try CSVReader.parse(data: data, configuration: config)
    }

    /// Reads a CSV file using the provided encoding and returns the CSV headers (if any) and all the CSV records.
    /// - parameter fileURL: The URL indicating the location of the file to be parsed.
    /// - parameter configuration: Closure receiving the default parsing configuration values and letting you  change them.
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Tuple with the CSV headers (empty if none) and all records within the CSV file.
    @inlinable public static func parse(fileURL: URL, configuration: (inout Configuration)->Void) throws -> Output {
        var config = Configuration()
        configuration(&config)
        return try CSVReader.parse(fileURL: fileURL, configuration: config)
    }
}
