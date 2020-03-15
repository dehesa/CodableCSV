import Foundation
#warning("CSVReader.header was previously and optional. Verify changes up the chain")
/// Reads CSV text data row-by-row.
///
/// The `CSVReader` is a sequential reader. It reads each line only once (i.e. it cannot re-read a previous CSV row).
public final class CSVReader: IteratorProtocol, Sequence {
    /// Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    public let configuration: Configuration
    /// Internal reader settings extracted from the public `configuration` and other values inferred during initialization.
    private let settings: CSVReader.Settings
    /// The header row for the given CSV.
    ///
    /// If empty, the file contained no headers.
    public let headers: [String]
    /// Unicode scalar buffer to keep scalars that hasn't yet been analysed.
    private let buffer: ScalarBuffer
    /// The unicode scalar iterator providing all input data.
    private let iterator: ScalarIterator
    /// Check whether the given unicode scalar is part of the field delimiter sequence.
    private let isFieldDelimiter: DelimiterChecker
    /// Check whether the given unicode scalar is par of the row delimiter sequence.
    private let isRowDelimiter: DelimiterChecker
    /// The amount of rows (counting the header row) that have been read and the amount of fields that should be in each row.
    internal private(set) var count: (rows: Int, fields: Int)
    /// The reader status indicating whether there are remaning lines to read, the CSV has been completely parsed, or an error occurred and no further operation shall be performed.
    public private(set) var status: Status
    /// Index of the row to be parsed next (i.e. a row not yet parsed).
    ///
    /// This index is NOT offseted by the existance of a header row. In other words:
    /// - If a CSV file has a header, the first row after a header (i.e. the first actual data row) will be the integer zero.
    /// - If a CSV file doesn't have a header, the first row to parse will also be zero.
    internal var rowIndex: Int { let r = self.count.rows; return self.headers.isEmpty ? r : r - 1 }
    
    /// Creates a reader instance that will be used to parse the given `String`.
    /// - parameter string: A `String` containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(string: String, configuration: Configuration = .init()) throws {
        let buffer = ScalarBuffer(reservingCapacity: 8)
        let iterator = ScalarIterator(scalarIterator: string.unicodeScalars.makeIterator())
        try self.init(configuration: configuration, buffer: buffer, iterator: iterator)
    }
    
    /// Creates a reader instance that will be used to parse the given data blob.
    ///
    /// If the configuration's encoding hasn't been set and the input data doesn't contain a Byte Order Marker (BOM), UTF8 is presumed.
    /// - parameter data: A data blob containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(data: Data, configuration: Configuration = .init()) throws {
        if configuration.presample, let dataEncoding = configuration.encoding {
            // A. If the `presample` configuration has been set and the user has explicitly mark an encoding, then the data can parsed into a string.
            guard let string = String(data: data, encoding: dataEncoding) else {
                throw CSVReader.Error(.invalidInput, reason: "The data blob didn't match the given string encoding.", help: "Let the reader infer the encoding or make sure the data blob is correctly formatted.", userInfo: ["String encoding": dataEncoding.rawValue])
            }
            try self.init(string: string, configuration: configuration)
        } else {
            // B. Otherwise, start parsing byte by byte.
            let buffer = ScalarBuffer(reservingCapacity: 8)
            // B.2. Check whether the input data has a BOM.
            var dataIterator = data.makeIterator()
            var unusedBytes: [UInt8] = .init()
            let inferredEncoding = try String.Encoding(iterator: &dataIterator, unusedBytes: &unusedBytes)
            // B.3. Select the appropriate encoding depending from the user provided encoding (if any), and the BOM encoding (if any).
            let encoding = try String.Encoding.selectFrom(provided: configuration.encoding, inferred: inferredEncoding)
            // B.4. Consume any byte used to identify the BOM and transform them into Unicode scalars (the actual BOM bytes are not included here).
            let scalars = try encoding.consume(bytes: unusedBytes, iterator: &dataIterator)
            buffer.append(scalars: scalars)
            // B.5. Create the scalar iterator.
            let iterator = try ScalarIterator(dataIterator: dataIterator, encoding: encoding)
            try self.init(configuration: configuration, buffer: buffer, iterator: iterator)
        }
    }
    
    /// Creates a reader instance that will be used to parse the given CSV file.
    ///
    /// If the configuration's encoding hasn't been set and the input data doesn't contain a Byte Order Marker (BOM), UTF8 is presumed.
    /// - parameter fileURL: The URL indicating the location of the file to be parsed.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - throws: `CSVReader.Error` exclusively.
    public convenience init(fileURL: URL, configuration: Configuration = .init()) throws {
        if configuration.presample {
            // A. If the `presample` configuration has been set, the file can be completely load into memory.
            try self.init(data: try Data(contentsOf: fileURL), configuration: configuration); return
        } else {
            // B. Otherwise, create an input stream and start parsing byte by byte.
            guard let stream = InputStream(url: fileURL) else {
                throw CSVReader.Error(.streamFailure, reason: "Creating an input stream to the given file URL failed.", help: "Make sure the URL is valid and you are allowed to access the file. Alternatively set the configuration's presample or load the file in a data blob and use the reader's data initializer.", userInfo: ["File URL": fileURL])
            }
            stream.open()
            do {
                // B.1. Create the iterator wrapper and the scalar buffer.
                let buffer = ScalarBuffer(reservingCapacity: 8)
                // B.2. Check whether the input data has a BOM.
                var unusedBytes: [UInt8] = .init()
                let inferredEncoding = try String.Encoding(stream: stream, unusedBytes: &unusedBytes)
                // B.3. Select the appropriate encoding depending from the user provided encoding (if any), and the BOM encoding (if any).
                let encoding = try String.Encoding.selectFrom(provided: configuration.encoding, inferred: inferredEncoding)
                // B.4. Consume any byte used to identify the BOM and transform them into Unicode scalars (the actual BOM bytes are not included here).
                let scalars = try encoding.consume(bytes: unusedBytes, stream: stream)
                buffer.append(scalars: scalars)
                // B.5. Create the scalar iterator.
                let iterator = try ScalarIterator(stream: stream, encoding: encoding)
                try self.init(configuration: configuration, buffer: buffer, iterator: iterator)
            } catch let error {
                stream.close()
                throw error
            }
        }
    }

    /// Designated initializer for the CSV reader.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - parameter buffer: A buffer storing in-flight `Unicode.Scalar`s.
    /// - parameter iterator: An iterator providing the CSV `Unicode.Scalar`s.
    /// - throws: `CSVReader.Error` exclusively.
    private init(configuration: Configuration, buffer: ScalarBuffer, iterator: ScalarIterator) throws {
        self.configuration = configuration
        self.buffer = buffer
        self.iterator = iterator
        var headers: [String] = []
        self.settings = try Settings(configuration: configuration, iterator: self.iterator, buffer: self.buffer, headers: &headers)
        self.headers = headers
        self.isFieldDelimiter = CSVReader.makeMatcher(delimiter: self.settings.delimiters.field, buffer: self.buffer, iterator: self.iterator)
        self.isRowDelimiter = CSVReader.makeMatcher(delimiter: self.settings.delimiters.row, buffer: self.buffer, iterator: self.iterator)
        self.status = .reading

        if self.headers.isEmpty {
            self.count = (0, 0)
        } else {
            self.count = (rows: 1, fields: self.headers.count)
        }
    }
}

extension CSVReader {
    /// Parses a CSV row.
    ///
    /// Since CSV parsing is sequential, if a previous call of this function encountered an error, subsequent calls will throw the same error.
    /// - throws: `CSVReader.Error` exclusively.
    /// - returns: The row's fields or `nil` if there isn't anything else to parse. The row will never be an empty array.
    public func parseRow() throws -> [String]? {
        switch self.status {
        case .reading: break
        case .finished: return nil
        case .failed(let e): throw e
        }
        
        let result: [String]?
        do {
            result = try self.parseLine()
        } catch let error {
            let e = error as! CSVReader.Error
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
    /// Parses a CSV row.
    /// - throws: `CSVReader.Error.invalidInput` exclusively.
    /// - returns: The row's fields or `nil` if there isn't anything else to parse. The row will never be an empty array.
    private func parseLine() throws -> [String]? {
        var result: [String] = []

        while true {
            // Try to retrieve an scalar (if not, it is EOF).
            guard let scalar = try self.buffer.next() ?? self.iterator.next() else {
                if result.isEmpty { return nil }
                result.append("")
                break
            }

            // Check for trimmed characters.
            if let set = self.settings.trimCharacters, set.contains(scalar) {
                continue
            }

            // If the unicode scalar retrieved is a double quote, an escaped field is awaiting for parsing.
            if scalar == self.settings.escapingScalar {
                let field = try self.parseEscapedField()
                result.append(field.value)
                if field.isAtEnd { break }
                // If the field delimiter is encountered, an implicit empty field has been defined.
            } else if try self.isFieldDelimiter(scalar) {
                result.append("")
                // If the row delimiter is encounter, an implicit empty field has been defined (for rows that already have content).
            } else if try self.isRowDelimiter(scalar) {
                guard !result.isEmpty else { return try self.parseRow() }
                result.append("")
                break
                // If a regular character is encountered, an "unescaped field" is awaiting parsing.
            } else {
                let field = try self.parseUnescapedField(starting: scalar)
                result.append(field.value)
                if field.isAtEnd { break }
            }
        }

        // If any row has previously parsed, we can check the number of expected fields.
        if self.count.rows > 0 {
            guard self.count.fields == result.count else {
                throw Error(.invalidInput, reason: "The number of fields is not constant between rows.", help: "Make sure the CSV file has always the same amount of fields per row.", userInfo: ["Row index": self.count.rows + 1, "Expected number of fields": self.count.fields, "Number of parsed files": result.count])
            }
        } else {
            self.count.fields = result.count
        }

        // Bump up the number of rows after this successful row parsing.
        self.count.rows += 1

        return result
    }

    /// Parses the awaiting unicode scalars expecting to form a "unescaped field".
    /// - parameter starting: The first regular scalar in the unescaped field.
    /// - throws: `CSVReader.Error.invalidInput` exclusively.
    /// - returns: The parsed field and whether the row/file ending characters have been found.
    private func parseUnescapedField(starting: Unicode.Scalar) throws -> (value: String, isAtEnd: Bool) {
        var field: String.UnicodeScalarView = .init(repeating: starting, count: 1)
        var reachedRowsEnd = false

        while true {
            // Try to retrieve an scalar (if not, it is EOF).
            guard let scalar = try self.buffer.next() ?? self.iterator.next() else {
                reachedRowsEnd = true
                break
            }

            // There cannot be double quotes on unescaped fields. If one is encountered, an error is thrown.
            if scalar == self.settings.escapingScalar {
                throw Error(.invalidInput, reason: "Quotes aren't allowed within fields which don't start with quotes.", help: "Sandwich the targeted field with quotes and escape the quote within the field.", userInfo: ["Row index": self.count.rows + 1])
                // If the field delimiter is encountered, return the already parsed characters.
            } else if try self.isFieldDelimiter(scalar) {
                reachedRowsEnd = false
                break
                // If the row delimiter is encountered, return the already parsed characters.
            } else if try self.isRowDelimiter(scalar) {
                reachedRowsEnd = true
                break
                // If it is a regular unicode scalar, just store it and continue parsing.
            } else {
                field.append(scalar)
            }
        }

        return (String(field), reachedRowsEnd)
    }

    /// Parses the awaiting unicode scalars expecting to form a "escaped field".
    /// - throws: `CSVReader.Error.invalidInput` exclusively.
    /// - returns: The parsed field and whether the row/file ending characters have been found.
    private func parseEscapedField() throws -> (value: String, isAtEnd: Bool) {
        var field: String.UnicodeScalarView = .init()
        var reachedRowsEnd = false

        fieldParsing: while true {
            // Try to retrieve an scalar (if not, it is EOF).
            // This case is not allowed without closing the escaping field first.
            guard let scalar = try self.buffer.next() ?? self.iterator.next() else {
                throw Error(.invalidInput, reason: "The last field is escaped (through quotes) and an EOF (End of File) was encountered before the field was properly closed (with a final quote character).", help: "End the targeted field with a quote.", userInfo: ["Row index": self.count.rows + 1])
            }

            // If the scalar is not a quote, just store it and continue parsing.
            guard scalar == self.settings.escapingScalar else {
                field.append(scalar)
                continue
            }

            // If a double quote scalar has been found within the field, retrieve the following scalar and check if it is EOF. If so, the field has finished and also the row and the file.
            guard var followingScalar = try self.buffer.next() ?? self.iterator.next() else {
                reachedRowsEnd = true
                break
            }

            // If another double quote is found, that is the escape sequence for one double quote scalar.
            if followingScalar == self.settings.escapingScalar {
                field.append(self.settings.escapingScalar)
                continue
            }

            // If characters can be trimmed.
            if let set = self.settings.trimCharacters {
                // Trim all the sequentials trimmable characters.
                while set.contains(scalar) {
                    guard let temporaryScalar = try self.buffer.next() ?? self.iterator.next() else {
                        reachedRowsEnd = true
                        break fieldParsing
                    }
                    followingScalar = temporaryScalar
                }
            }

            if try self.isFieldDelimiter(followingScalar) {
                break
            } else if try self.isRowDelimiter(followingScalar) {
                reachedRowsEnd = true
                break
            } else {
                throw Error(.invalidInput, reason: "Only delimiters or EOF characters are allowed after escaped fields.", help: "Delete any extra character at the end of the targeted row.", userInfo: ["Row index": self.count.rows + 1])
            }
        }

        return (String(field), reachedRowsEnd)
    }
}

extension CSVReader {
    /// Closure accepting a scalar and returning a Boolean indicating whether the scalar (and subsquent unicode scalars) form a delimiter.
    private typealias DelimiterChecker = (_ scalar: Unicode.Scalar) throws -> Bool

    /// Creates a delimiter identifier closure.
    /// - parameter view: The unicode characters forming a targeted delimiter.
    /// - parameter buffer: A unicode character buffer containing further characters to parse.
    /// - parameter iterator: A unicode character buffer containing further characters to parse.
    /// - returns: A closure which given the targeted unicode character and the buffer and iterrator, returns a Boolean indicating whether there is a delimiter.
    private static func makeMatcher(delimiter view: String.UnicodeScalarView, buffer: ScalarBuffer, iterator: ScalarIterator) -> DelimiterChecker {
        // This should never be triggered.
        precondition(!view.isEmpty, "Delimiters must include at least one unicode scalar.")

        // For optimizations sake, a delimiter proofer is built for a single unicode scalar.
        if view.count == 1 {
            let delimiter: Unicode.Scalar = view.first!
            return { delimiter == $0 }
        // For optimizations sake, a delimiter proofer is built for two unicode scalars.
        } else if view.count == 2 {
            let firstDelimiter = view.first!
            let secondDelimiter = view[view.index(after: view.startIndex)]

            return { [unowned buffer, unowned iterator] in
                guard firstDelimiter == $0, let secondScalar = try buffer.next() ?? iterator.next() else {
                    return false
                }

                let result = secondDelimiter == secondScalar
                if !result {
                    buffer.preppend(scalar: secondScalar)
                }
                return result
            }
        // For completion sake, a delimiter proofer is build for +2 unicode scalars.
        // CSV files with multiscalar delimiters are very very rare.
        } else {
            return { [unowned buffer, unowned iterator] (firstScalar) -> Bool in
                var scalar = firstScalar
                var index = view.startIndex
                var toIncludeInBuffer: [Unicode.Scalar] = .init()

                while true {

                    guard scalar == view[index] else {
                        buffer.preppend(scalars: toIncludeInBuffer)
                        return false
                    }

                    index = view.index(after: index)
                    guard index < view.endIndex else {
                        return true
                    }

                    guard let nextScalar = try buffer.next() ?? iterator.next() else {
                        buffer.preppend(scalars: toIncludeInBuffer)
                        return false
                    }

                    toIncludeInBuffer.append(nextScalar)
                    scalar = nextScalar
                }
            }
        }
    }
}
