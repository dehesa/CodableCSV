import Foundation

/// Reads a text files and returns paramtrized outputs.
public final class CSVReader: IteratorProtocol, Sequence {
    /// Generic configuration variables for the reader.
    public let configuration: CSV.Configuration
    /// The header row for the given CSV.
    public private(set) var headers: [String]? = nil
    
    /// Specific configuration variables for these CSV parsing passes.
    fileprivate let internals: CSVReader.Configuration
    /// The unicode scalar iterator providing all input.
    fileprivate let iterator: AnyIterator<Unicode.Scalar>
    /// Unicode scalar buffer to keep scalars that hasn't yet been analysed.
    fileprivate let buffer: Buffer
    /// Check whether the given unicode scalar is part of the field delimiter sequence.
    fileprivate let isFieldDelimiter: (_ scalar: Unicode.Scalar) -> Bool
    /// Check whether the given unicode scalar is par of the row delimiter sequence.
    fileprivate let isRowDelimiter: (_ scalar: Unicode.Scalar) -> Bool
    /// The amount of rows (counting the header row) that have been read and the amount of fields that should be in each row.
    internal fileprivate(set) var count: (rows: Int, fields: Int) = (0, 0)
    /// If the file encountered a previous error, it will be stored here.
    ///
    /// Encountering an error renders following parsing attempts imposible.
    fileprivate var errorEncountered: CSVReader.Error? = nil
    
    /// Designated initializer with the unicode scalar source and the reader configuration.
    /// - parameter iterator: The source provider of unicode scalars. It is consider a once read-only stream.
    /// - parameter configuration: Generic configuration when dealing with CSV files.
    /// - throws: `CSVReader.Error` exclusively.
    internal init<T:IteratorProtocol>(iterator: T, configuration: CSV.Configuration) throws where T.Element == Unicode.Scalar {
        self.iterator = AnyIterator(iterator)
        self.buffer = Buffer()
        
        self.configuration = configuration
        self.internals = try Configuration(configuration: configuration, iterator: self.iterator, buffer: self.buffer)
        
        self.isFieldDelimiter = CSVReader.matchCreator(delimiter: self.internals.delimiters.field, buffer: self.buffer, iterator: self.iterator)
        self.isRowDelimiter = CSVReader.matchCreator(delimiter: self.internals.delimiters.row, buffer: self.buffer, iterator: self.iterator)
        
        guard self.internals.hasHeader else { return }
        guard let header = try self.parseLine() else { throw Error.invalidInput(message: "The CSV file didn't have a header row.") }
        self.headers = header
        self.count = (rows: 1, fields: header.count)
    }
    
    /// - warning: If the CSV file being parsed contains invalid characters, this function will crash. For safer parsing use `parseRow()`.
    /// - seealso: parseRow()
    public func next() -> [String]? {
        return try! self.parseRow()
    }
    
    /// Index of the row to be parsed
    ///
    /// This index is NOT offset by the existance of a header row.
    /// In other words, the first row after a header in a file will be the integer zero. If a CSV file the first row to parse will also be zero.
    internal var rowIndex: Int {
        if self.internals.hasHeader {
            return count.rows - 1
        } else {
            return count.rows
        }
    }
}

extension CSVReader {
    /// Parses a CSV row.
    ///
    /// Since CSV parsing is sequential, if a previous call of this function encountered an error, subsequent calls will throw the same error.
    /// - returns: The row's fields or `nil` if there isn't anything else to parse. The row will never be an empty array.
    /// - throws: `CSVReader.Error.invalidInput(message:)` exclusively.
    public func parseRow() throws -> [String]? {
        guard case .none = self.errorEncountered else {
            throw self.errorEncountered!
        }
        
        do {
            return try self.parseLine()
        } catch let error as CSVReader.Error {
            self.errorEncountered = error
            throw error
        } catch let error {
            fatalError("Unexpected error when parsing a row: \(error)")
        }
    }
    
    /// Parses a CSV row.
    /// - returns: The row's fields or `nil` if there isn't anything else to parse. The row will never be an empty array.
    /// - throws: `CSVReader.Error.invalidInput(message:)` exclusively.
    fileprivate func parseLine() throws -> [String]? {
        var result: [String] = []
        
        while true {
            // Try to retrieve an scalar (if not, it is EOF).
            guard let scalar = self.buffer.next() ?? self.iterator.next() else {
                if result.isEmpty { return nil }
                result.append("")
                break
            }
            
            // Check for trimmed characters.
            if let set = self.internals.trimCharacters, set.contains(scalar) {
                continue
            }
            
            // If the unicode scalar retrieved is a double quote, an escaped field is awaiting for parsing.
            if scalar == self.internals.escapingScalar {
                let field = try self.parseEscapedField()
                result.append(field.value)
                if field.isAtEnd { break }
                // If the field delimiter is encountered, an implicit empty field has been defined.
            } else if self.isFieldDelimiter(scalar) {
                result.append("")
                // If the row delimiter is encounter, an implicit empty field has been defined (for rows that already have content).
            } else if self.isRowDelimiter(scalar) {
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
        
        // If any other row has already been parsed, we can check if the amount of field has been kept constant (as it is demanded).
        if self.count.rows > 0 {
            guard self.count.fields == result.count else {
                throw Error.invalidInput(message: "The number of fields is not constant. \(self.count.fields) fields were expected and \(result.count) were parsed in row at index \(self.count.rows + 1).")
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
    /// - returns: The parsed field and whether the row/file ending characters have been found.
    /// - throws: `CSVReader.Error.invalidInput(message:)` exclusively.
    private func parseUnescapedField(starting: Unicode.Scalar) throws -> (value: String, isAtEnd: Bool) {
        var field: String.UnicodeScalarView = .init(repeating: starting, count: 1)
        var reachedRowsEnd = false
        
        while true {
            // Try to retrieve an scalar (if not, it is EOF).
            guard let scalar = self.buffer.next() ?? self.iterator.next() else {
                reachedRowsEnd = true
                break
            }
            
            // There cannot be double quotes on unescaped fields. If one is encountered, an error is thrown.
            if scalar == self.internals.escapingScalar {
                throw Error.invalidInput(message: "Quotes aren't allowed within fields that don't start with quotes.")
                // If the field delimiter is encountered, return the already parsed characters.
            } else if self.isFieldDelimiter(scalar) {
                reachedRowsEnd = false
                break
                // If the row delimiter is encountered, return the already parsed characters.
            } else if self.isRowDelimiter(scalar) {
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
    /// - returns: The parsed field and whether the row/file ending characters have been found.
    /// - throws: `CSVReader.Error.invalidInput(message:)` exclusively.
    private func parseEscapedField() throws -> (value: String, isAtEnd: Bool) {
        var field: String.UnicodeScalarView = .init()
        var reachedRowsEnd = false
        
        fieldParsing: while true {
            // Try to retrieve an scalar (if not, it is EOF).
            // This case is not allowed without closing the escaping field first.
            guard let scalar = self.buffer.next() ?? self.iterator.next() else {
                throw Error.invalidInput(message: "The last field is escaped (through quotes) and an EOF (End of File) was encountered before the field was properly closed (with a final quote character).")
            }
            
            // If the scalar is not a quote, just store it and continue parsing.
            guard scalar == self.internals.escapingScalar else {
                field.append(scalar)
                continue
            }
            
            // If a double quote scalar has been found within the field, retrieve the following scalar and check if it is EOF. If so, the field has finished and also the row and the file.
            guard var followingScalar = self.buffer.next() ?? self.iterator.next() else {
                reachedRowsEnd = true
                break
            }
            
            // If another double quote is found, that is the escape sequence for one double quote scalar.
            if followingScalar == self.internals.escapingScalar {
                field.append(self.internals.escapingScalar)
                continue
            }
            
            // If characters can be trimmed.
            if let set = self.internals.trimCharacters {
                // Trim all the sequentials trimmable characters.
                while set.contains(scalar) {
                    guard let temporaryScalar = self.buffer.next() ?? self.iterator.next() else {
                        reachedRowsEnd = true
                        break fieldParsing
                    }
                    followingScalar = temporaryScalar
                }
            }
            
            if self.isFieldDelimiter(followingScalar) {
                break
            } else if self.isRowDelimiter(followingScalar) {
                reachedRowsEnd = true
                break
            } else {
                throw Error.invalidInput(message: "Only delimiters or EOF characters are allowed after escaped fields.")
            }
        }
        
        return (String(field), reachedRowsEnd)
    }
    
    /// Creates a delimiter identifier closure.
    /// - parameter view: The unicode characters forming a targeted delimiter.
    /// - parameter buffer: A unicode character buffer containing further characters to parse.
    /// - parameter iterator: A unicode character buffer containing further characters to parse.
    /// - returns: A closure which given the targeted unicode character and the buffer and iterrator, returns a Boolean indicating whether there is a delimiter.
    fileprivate static func matchCreator(delimiter view: String.UnicodeScalarView, buffer: Buffer, iterator: AnyIterator<Unicode.Scalar>) -> (_ scalar: Unicode.Scalar) -> Bool {
        // This should never be triggered.
        precondition(!view.isEmpty, "Delimiters must include at least one unicode scalar.")
        
        // For optimizations sake, a delimiter proofer is build for a single unicode scalar.
        if view.count == 1 {
            let delimiter = view.first!
            return { delimiter == $0 }
            // For optimizations sake, a delimiter proofer is build for two unicode scalars.
        } else if view.count == 2 {
            let firstDelimiter = view.first!
            let secondDelimiter = view[view.index(after: view.startIndex)]
            
            return {
                guard firstDelimiter == $0, let secondScalar = buffer.next() ?? iterator.next() else {
                    return false
                }
                
                let result = secondDelimiter == secondScalar
                if !result {
                    buffer.preppend(scalar: secondScalar)
                }
                return result
            }
            // For completion sake, a delimiter proofer is build for +2 unicode scalars.
            // CSV files with multiscalar delimiters are very very rare (if not existant).
        } else {
            return { (scalar) -> Bool in
                var scalar = scalar
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
                    
                    guard let nextScalar = buffer.next() ?? iterator.next() else {
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
