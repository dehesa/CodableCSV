import Foundation

extension CSVReader {
    /// Creates a reader instance to go over a Swift String.
    /// - note: This method will have whole string in memory; thus, if the CSV is very big you may experience a loss in performance.
    /// - parameter string: A Swift String containing CSV formatted data.
    /// - parameter configuration: Generic explanation on how the CSV is formatted.
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(string: String, configuration: Configuration = .init()) throws {
        let iterator = string.unicodeScalars.makeIterator()
        try self.init(iterator: iterator, configuration: configuration)
    }
    
    /// Creates a reader instance to go over a blob of data.
    /// - note: This method will have the whole data blob in memory; thus, if the CSV is very big you may experience a loss in performance.
    /// - parameter data: A blob of data containing CSV formatted data.
    /// - parameter encoding: `String` encoding used to transform the data blob into text; or `nil` if you want the algorith to try to figure it out.
    /// - parameter configuration: Generic explanation on how the CSV is formatted.
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(data: Data, encoding: String.Encoding? = .utf8, configuration: Configuration = .init()) throws {
        var blob = data
        #warning("The CSVReader should be encoding independing. That is why it must be kept as unicode scalar iterator.")
        #warning("The BOM detection must happen whether a data blob or a file handle is received")
        let finalEncoding: String.Encoding
        switch (encoding, blob.removeBOM()) {
        case (.none, let e?):  finalEncoding = e
        case (let e?, .none):  finalEncoding = e
        case (let p?, let e?) where p==e: finalEncoding = p
        case (let p?, let e?): throw Error.invalidInput(#"The String encoding provided "\#(p)" doesn't match the Byte Order Mark on the file "\#(e)""#)
        case (.none,  .none):  throw Error.invalidInput("The String encoding for the data blob couldn't be inferred. Please pass a specific one.")
        }
        
        guard let string = String(data: blob, encoding: finalEncoding) else {
            throw Error.invalidInput("The data blob couldn't be mapped to the given String encoding (\(finalEncoding.rawValue))")
        }
        
        try self.init(string: string, configuration: configuration)
    }
//
//    /// Creates a reader instance to go over a CSV file.
//    /// - parameter file: The URL indicating the location of the file to be parsed.
//    /// - parameter encoding: `String` encoding used to transform the data blob into text; or `nil` if you want the algorith to try to figure it out.
//    /// - parameter configuration: Generic explanation on how the CSV is formatted.
//    /// - throws: `CSVReader.Error` exclusively.
//    public convenience init(fileURL: URL, encoding: String.Encoding? = .utf8, configuration: Configuration = .init()) throws {
//        guard let stream = InputStream(url: file) else {
//            throw Error.invalidInput("The file under path '\(file.path)' couldn't be opened")
//        }
//        #warning("Make CSVReader accept an input stream")
////        let reader = CSVReader(iterator: <#T##IteratorProtocol#>, configuration: configuration)
//        fatalError()
//    }
//
//    public convenience init(file: FileHandle, encoding: String.Encoding? = .utf8, configuration: Configuration = .init()) throws {
//
//    }
}

extension CSVReader {
    /// The result of a whole CSV file parsing.
    /// - parameter headers: If the CSV contained a header row, this parameter will be set.
    /// - parameter rows: An ordered list of CSV rows.
    public typealias ParsingResult = (headers: [String]?, rows: [[String]])
    
    /// Reads the Swift String and returns the headers (if any) and all the rows.
    ///
    /// Parsing instead of relying on `Sequence` functionality (such as for..in.., map, etc.) will give you the benefit of throwing an error (and not crashing) when encountering a CSV format mistake.
    /// - note: This method will have whole string in memory; thus, if the CSV is very big you may experience a loss in performance.
    /// - parameter string: A Swift String containing CSV formatted data.
    /// - parameter configuration: Generic explanation on how the CSV is formatted.
    /// - throws: `CSVReader.Error` exclusively.
    public static func parse(string: String, configuration: Configuration = .init()) throws -> ParsingResult {
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
    /// - parameter encodign: `String` encoding used to transform the data blob into text; or `nil` if you want the algorith to try to figure it out.
    /// - parameter configuration: Generic explanation on how the CSV is formatted.
    /// - throws: `CSVReader.Error` exclusively.
    public static func parse(data: Data, encoding: String.Encoding? = .utf8, configuration: Configuration = .init()) throws -> ParsingResult {
        guard let encoding = encoding ?? data.inferEncoding() else {
            throw Error.invalidInput("The `String` encoding for the data blob couldn't be inferred. Please pass a specific one.")
        }
        
        guard let string = String(data: data, encoding: encoding) else {
            throw Error.invalidInput("The data blob couldn't be encoded with the given encoding (rawValue: \(encoding.rawValue))")
        }
        
        return try self.parse(string: string, configuration: configuration)
    }
}
