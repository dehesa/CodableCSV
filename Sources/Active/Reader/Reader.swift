import Foundation
#warning("CSVReader header was previously and optional, now it is just a string. Verify changes up the chain")
/// Reads CSV text data row-by-row.
///
/// The `CSVReader` is a sequential reader. It reads each line only once (i.e. it cannot re-read a previous CSV row).
public final class CSVReader: IteratorProtocol, Sequence {
    /// Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    public let configuration: Configuration
    /// The header row for the given CSV.
    public let headers: [String]
    /// The reader status indicating whether there are remaning lines to read, the CSV has been completely parsed, or an error occurred and no further operation shall be performed.
    public private(set) var status: Status
    /// The instance actually parsing bytes/unicode scalars.
    private let reader: ShadowReader
    
    /// Creates a reader instance that will be used to parse the given `String`.
    /// - parameter string: A `String` containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVReader.Error` exclusively.
    public init(string: String, configuration: Configuration = .init()) throws {
        self.configuration = configuration
        let buffer = ScalarBuffer(reservingCapacity: 20)
        // 1. Get unicode scalar iterator.
        var iterator = string.unicodeScalars.makeIterator()
        #warning("Is the BOM at the beginning of the string?")
        // 2. Figure out CSVReader settings.
        var headers: [String] = []
        let settings = try Settings(configuration: configuration, iterator: &iterator, buffer: buffer, headers: &headers)
        self.headers = headers
        // 3. Initialize reader
        self.reader = try StringReader(iterator: iterator, settings: settings, buffer: buffer)
        self.status = .reading
    }
    
    ///
    private init<I>(iterator: I, encoding: String.Encoding?, configuration: Configuration) throws where I:IteratorProtocol, I.Element==UInt8 {
        // Check encoding is manifested in the bytes.
        fatalError()
        
//        let dataEncoding = String.Encoding(iterator: &byteIterator, buffer: <#T##ScalarBuffer#>)
//        //            let scalarIterator = String.Encoding.scalarDecoder(iterator: Data.Iterator.self)
//
//        fatalError()
    }
    
    /// Creates a reader instance that will be used to parse the given data blob.
    /// - parameter data: A data blob containing CSV formatted data.
    /// - parameter encoding: `String` encoding used to transform the data blob into text; or `nil` if you want the algorith to try to figure it out.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(data: Data, encoding: String.Encoding? = .utf8, configuration: Configuration = .init()) throws {
        guard configuration.presample, let dataEncoding = encoding else {
            try self.init(iterator: data.makeIterator(), encoding: encoding, configuration: configuration)
            return
        }
        
        guard let string = String(data: data, encoding: dataEncoding) else {
            throw Error.invalidInput("The data blob couldn't be mapped to the String encoding '\(dataEncoding.rawValue)'")
        }
        
        try self.init(string: string, configuration: configuration)
    }
    
    /// Creates a reader instance that will be used to parse the given CSV file.
    /// - parameter file: The URL indicating the location of the file to be parsed.
    /// - parameter encoding: `String` encoding used to transform the data blob into text; or `nil` if you want the algorith to try to figure it out.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(file: URL, encoding: String.Encoding? = .utf8, configuration: Configuration = .init()) throws {
        guard !configuration.presample else {
            let data = try Data(contentsOf: file)
            try self.init(data: data, encoding: encoding, configuration: configuration)
            return
        }
        
        guard let stream = InputStream(url: file) else {
            throw Error.invalidInput("The file under path '\(file.path)' couldn't be opened")
        }
        
        #error("Continue here!!!")
        
        #warning("Make CSVReader accept an input stream")
        fatalError()
    }
}

extension CSVReader {
    /// The amount of rows (counting the header row) that have been read and the amount of fields that should be in each row.
    internal var count: (rows: Int, fields: Int) {
        self.reader.count
    }
    
    /// Index of the row to be parsed next (i.e. a row not yet parsed).
    ///
    /// This index is NOT offseted by the existance of a header row. In other words:
    /// - If a CSV file has a header, the first row after a header (i.e. the first actual data row) will be the integer zero.
    /// - If a CSV file doesn't have a header, the first row to parse will also be zero.
    internal var rowIndex: Int {
        let rows = self.reader.count.rows
        return self.headers.isEmpty ? rows : rows - 1
    }
    
    /// Parses a CSV row.
    ///
    /// Since CSV parsing is sequential, if a previous call of this function encountered an error, subsequent calls will throw the same error.
    /// - throws: `CSVReader.Error.invalidInput` exclusively.
    /// - returns: The row's fields or `nil` if there isn't anything else to parse. The row will never be an empty array.
    public func parseRow() throws -> [String]? {
        switch self.status {
        case .reading: break
        case .finished: return nil
        case .failed(let e): throw e
        }
        
        let result: [String]?
        do {
            result = try self.reader.parseLine()
        } catch let error {
            guard let e = error as? CSVReader.Error else { fatalError("Unexpected error when parsing a row: \(error)") }
            self.status = .failed(e)
            throw e
        }
        
        if case .none = result { self.status = .finished }
        return result
    }
    
    /// - warning: If the CSV file being parsed contains invalid characters, this function will crash. For safer parsing use `parseRow()`.
    /// - seealso: parseRow()
    public func next() -> [String]? {
        return try! self.parseRow()
    }
}

extension CSVReader {
    /// The result of a whole CSV file parsing.
    /// - parameter headers: If the CSV contained a header row, this parameter will contain elements.
    /// - parameter rows: An ordered list of CSV rows.
    public typealias ParsingResult = (headers: [String], rows: [[String]])
    
    /// Reads the Swift String and returns the headers (if any) and all the rows.
    ///
    /// Parsing instead of relying on `Sequence` functionality (such as for..in.., map, etc.) will give you the benefit of throwing an error (and not crashing) when encountering a CSV format mistake.
    /// - parameter string: A `String` containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
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
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVReader.Error` exclusively.
    public static func parse(data: Data, encoding: String.Encoding? = .utf8, configuration: Configuration = .init()) throws -> ParsingResult {
        let reader = try CSVReader(data: data, encoding: encoding, configuration: configuration)
        
        var result: [[String]] = .init()
        while let row = try reader.parseRow() {
            result.append(row)
        }
        
        return (reader.headers, result)
    }
    
    ///
    public static func parse(file: URL, encoding: String.Encoding? = .utf8, configuration: Configuration = .init()) throws -> ParsingResult {
        let reader = try CSVReader(file: file, encoding: encoding, configuration: configuration)
        
        var result: [[String]] = .init()
        while let row = try reader.parseRow() {
            result.append(row)
        }
        return (reader.headers, result)
    }
}


//public final class CSVReader: IteratorProtocol, Sequence {
//    /// Check whether the given unicode scalar is part of the field delimiter sequence.
//    private let isFieldDelimiter: DelimiterChecker
//    /// Check whether the given unicode scalar is par of the row delimiter sequence.
//    private let isRowDelimiter: DelimiterChecker
//    /// The amount of rows (counting the header row) that have been read and the amount of fields that should be in each row.
//    internal private(set) var count: (rows: Int, fields: Int) = (0, 0)
//
//    /// Designated initializer with the unicode scalar source and the reader configuration.
//    /// - parameter iterator: The source provider of unicode scalars. It is consider a once read-only stream.
//    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
//    /// - throws: `CSVReader.Error` exclusively.
//    internal init(iterator: AnyIterator<Unicode.Scalar>, configuration: Configuration) throws {
//        self.headers = nil
//        self.status = .reading
//        self.iterator = iterator
//        self.buffer = ScalarBuffer()
//        self.settings = try Settings(configuration: configuration, iterator: self.iterator, buffer: self.buffer)
//
//        self.isFieldDelimiter = CSVReader.makeMatcher(delimiter: self.settings.delimiters.field, buffer: self.buffer, iterator: self.iterator)
//        self.isRowDelimiter = CSVReader.makeMatcher(delimiter: self.settings.delimiters.row, buffer: self.buffer, iterator: self.iterator)
//
//        if self.settings.hasHeader {
//            let header = try self.parseLine() ?! Error.invalidInput("The CSV file didn't have a header row.")
//            self.headers = header
//            self.count = (rows: 1, fields: header.count)
//        }
//    }
//}
//
//extension CSVReader {
//    /// Parses a CSV row.
//    /// - throws: `CSVReader.Error.invalidInput` exclusively.
//    /// - returns: The row's fields or `nil` if there isn't anything else to parse. The row will never be an empty array.
//    private func parseLine() throws -> [String]? {
//        var result: [String] = []
//
//        while true {
//            // Try to retrieve an scalar (if not, it is EOF).
//            guard let scalar = self.buffer.next() ?? self.iterator.next() else {
//                if result.isEmpty { return nil }
//                result.append("")
//                break
//            }
//
//            // Check for trimmed characters.
//            if let set = self.settings.trimCharacters, set.contains(scalar) {
//                continue
//            }
//
//            // If the unicode scalar retrieved is a double quote, an escaped field is awaiting for parsing.
//            if scalar == self.settings.escapingScalar {
//                let field = try self.parseEscapedField()
//                result.append(field.value)
//                if field.isAtEnd { break }
//                // If the field delimiter is encountered, an implicit empty field has been defined.
//            } else if self.isFieldDelimiter(scalar) {
//                result.append("")
//                // If the row delimiter is encounter, an implicit empty field has been defined (for rows that already have content).
//            } else if self.isRowDelimiter(scalar) {
//                guard !result.isEmpty else { return try self.parseRow() }
//                result.append("")
//                break
//                // If a regular character is encountered, an "unescaped field" is awaiting parsing.
//            } else {
//                let field = try self.parseUnescapedField(starting: scalar)
//                result.append(field.value)
//                if field.isAtEnd { break }
//            }
//        }
//
//        // If any other row has already been parsed, we can check if the amount of field has been kept constant (as it is demanded).
//        if self.count.rows > 0 {
//            guard self.count.fields == result.count else {
//                throw Error.invalidInput("The number of fields is not constant. \(self.count.fields) fields were expected and \(result.count) were parsed in row at index \(self.count.rows + 1).")
//            }
//        } else {
//            self.count.fields = result.count
//        }
//
//        // Bump up the number of rows after this successful row parsing.
//        self.count.rows += 1
//
//        return result
//    }
//
//    /// Parses the awaiting unicode scalars expecting to form a "unescaped field".
//    /// - parameter starting: The first regular scalar in the unescaped field.
//    /// - throws: `CSVReader.Error.invalidInput` exclusively.
//    /// - returns: The parsed field and whether the row/file ending characters have been found.
//    private func parseUnescapedField(starting: Unicode.Scalar) throws -> (value: String, isAtEnd: Bool) {
//        var field: String.UnicodeScalarView = .init(repeating: starting, count: 1)
//        var reachedRowsEnd = false
//
//        while true {
//            // Try to retrieve an scalar (if not, it is EOF).
//            guard let scalar = self.buffer.next() ?? self.iterator.next() else {
//                reachedRowsEnd = true
//                break
//            }
//
//            // There cannot be double quotes on unescaped fields. If one is encountered, an error is thrown.
//            if scalar == self.settings.escapingScalar {
//                throw Error.invalidInput("Quotes aren't allowed within fields that don't start with quotes.")
//                // If the field delimiter is encountered, return the already parsed characters.
//            } else if self.isFieldDelimiter(scalar) {
//                reachedRowsEnd = false
//                break
//                // If the row delimiter is encountered, return the already parsed characters.
//            } else if self.isRowDelimiter(scalar) {
//                reachedRowsEnd = true
//                break
//                // If it is a regular unicode scalar, just store it and continue parsing.
//            } else {
//                field.append(scalar)
//            }
//        }
//
//        return (String(field), reachedRowsEnd)
//    }
//
//    /// Parses the awaiting unicode scalars expecting to form a "escaped field".
//    /// - throws: `CSVReader.Error.invalidInput` exclusively.
//    /// - returns: The parsed field and whether the row/file ending characters have been found.
//    private func parseEscapedField() throws -> (value: String, isAtEnd: Bool) {
//        var field: String.UnicodeScalarView = .init()
//        var reachedRowsEnd = false
//
//        fieldParsing: while true {
//            // Try to retrieve an scalar (if not, it is EOF).
//            // This case is not allowed without closing the escaping field first.
//            guard let scalar = self.buffer.next() ?? self.iterator.next() else {
//                throw Error.invalidInput("The last field is escaped (through quotes) and an EOF (End of File) was encountered before the field was properly closed (with a final quote character).")
//            }
//
//            // If the scalar is not a quote, just store it and continue parsing.
//            guard scalar == self.settings.escapingScalar else {
//                field.append(scalar)
//                continue
//            }
//
//            // If a double quote scalar has been found within the field, retrieve the following scalar and check if it is EOF. If so, the field has finished and also the row and the file.
//            guard var followingScalar = self.buffer.next() ?? self.iterator.next() else {
//                reachedRowsEnd = true
//                break
//            }
//
//            // If another double quote is found, that is the escape sequence for one double quote scalar.
//            if followingScalar == self.settings.escapingScalar {
//                field.append(self.settings.escapingScalar)
//                continue
//            }
//
//            // If characters can be trimmed.
//            if let set = self.settings.trimCharacters {
//                // Trim all the sequentials trimmable characters.
//                while set.contains(scalar) {
//                    guard let temporaryScalar = self.buffer.next() ?? self.iterator.next() else {
//                        reachedRowsEnd = true
//                        break fieldParsing
//                    }
//                    followingScalar = temporaryScalar
//                }
//            }
//
//            if self.isFieldDelimiter(followingScalar) {
//                break
//            } else if self.isRowDelimiter(followingScalar) {
//                reachedRowsEnd = true
//                break
//            } else {
//                throw Error.invalidInput("Only delimiters or EOF characters are allowed after escaped fields.")
//            }
//        }
//
//        return (String(field), reachedRowsEnd)
//    }
//}
//
//extension CSVReader {
//    /// Closure accepting a scalar and returning a Boolean indicating whether the scalar (and subsquent unicode scalars) form a delimiter.
//    private typealias DelimiterChecker = (_ scalar: Unicode.Scalar) -> Bool
//
//    /// Creates a delimiter identifier closure.
//    /// - parameter view: The unicode characters forming a targeted delimiter.
//    /// - parameter buffer: A unicode character buffer containing further characters to parse.
//    /// - parameter iterator: A unicode character buffer containing further characters to parse.
//    /// - returns: A closure which given the targeted unicode character and the buffer and iterrator, returns a Boolean indicating whether there is a delimiter.
//    private static func makeMatcher(delimiter view: String.UnicodeScalarView, buffer: ScalarBuffer, iterator: AnyIterator<Unicode.Scalar>) -> DelimiterChecker {
//        // This should never be triggered.
//        precondition(!view.isEmpty, "Delimiters must include at least one unicode scalar.")
//
//        // For optimizations sake, a delimiter proofer is built for a single unicode scalar.
//        if view.count == 1 {
//            let delimiter = view.first!
//            return { delimiter == $0 }
//        // For optimizations sake, a delimiter proofer is built for two unicode scalars.
//        } else if view.count == 2 {
//            let firstDelimiter = view.first!
//            let secondDelimiter = view[view.index(after: view.startIndex)]
//
//            return { [unowned buffer] in
//                guard firstDelimiter == $0, let secondScalar = buffer.next() ?? iterator.next() else {
//                    return false
//                }
//
//                let result = secondDelimiter == secondScalar
//                if !result {
//                    buffer.preppend(scalar: secondScalar)
//                }
//                return result
//            }
//        // For completion sake, a delimiter proofer is build for +2 unicode scalars.
//        // CSV files with multiscalar delimiters are very very rare (if non-existant).
//        } else {
//            return { [unowned buffer] (firstScalar) -> Bool in
//                var scalar = firstScalar
//                var index = view.startIndex
//                var toIncludeInBuffer: [Unicode.Scalar] = .init()
//
//                while true {
//
//                    guard scalar == view[index] else {
//                        buffer.preppend(scalars: toIncludeInBuffer)
//                        return false
//                    }
//
//                    index = view.index(after: index)
//                    guard index < view.endIndex else {
//                        return true
//                    }
//
//                    guard let nextScalar = buffer.next() ?? iterator.next() else {
//                        buffer.preppend(scalars: toIncludeInBuffer)
//                        return false
//                    }
//
//                    toIncludeInBuffer.append(nextScalar)
//                    scalar = nextScalar
//                }
//            }
//        }
//    }
//}
