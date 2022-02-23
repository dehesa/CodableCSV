/// Reads CSV text data row-by-row.
///
/// The `CSVReader` is a sequential reader. It reads each line only once (i.e. it cannot re-read a previous CSV row).
public final class CSVReader: IteratorProtocol, Sequence {
  /// Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
  public let configuration: Configuration
  /// Internal reader settings extracted from the public `configuration` and other values inferred during initialization.
  private let _settings: Settings
  /// The header row for the given CSV.
  ///
  /// If empty, the file contained no headers.
  private(set) public var headers: [String]
  /// Lookup dictionary providing fast index discovery for header names.
  private(set) var headerLookup: [Int:Int]?
  /// Unicode scalar buffer to keep scalars that hasn't yet been analyzed.
  private let _scalarBuffer: ScalarBuffer
  /// Intermediate variable re-used for optimization purposes.
  private var _fieldBuffer: [Unicode.Scalar]
  /// The unicode scalar decoder providing all input data.
  private let _decoder: ScalarDecoder
  /// Check whether the given unicode scalar is part of the field delimiter sequence.
  private let _isFieldDelimiter: Delimiter.Scalars.Checker
  /// Check whether the given unicode scalar is par of the row delimiter sequence.
  private let _isRowDelimiter: Delimiter.Scalars.Checker
  /// The amount of rows (counting the header row) that have been read and the amount of fields that should be in each row.
  private(set) var count: (rows: Int, fields: Int)
  /// The reader status indicating whether there are remaining lines to read, the CSV has been completely parsed, or an error occurred and no further operation shall be performed.
  public private(set) var status: Status

  /// Designated initializer for the CSV reader.
  /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
  /// - parameter buffer: A buffer storing in-flight `Unicode.Scalar`s.
  /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
  /// - throws: `CSVError<CSVReader>` exclusively.
  init(configuration: Configuration, buffer: ScalarBuffer, decoder: @escaping ScalarDecoder) throws {
    self.configuration = configuration
    self._settings = try Settings(configuration: configuration, decoder: decoder, buffer: buffer)
    (self.headers, self.headerLookup) = (Array(), nil)
    self._scalarBuffer = buffer
    self._fieldBuffer = Array()
    self._fieldBuffer.reserveCapacity(128)
    self._decoder = decoder
    self._isFieldDelimiter = self._settings.delimiters.makeFieldMatcher(buffer: self._scalarBuffer, decoder: self._decoder)
    self._isRowDelimiter = self._settings.delimiters.makeRowMatcher(buffer: self._scalarBuffer, decoder: self._decoder)
    self.count = (0, 0)
    self.status = .active

    switch configuration.headerStrategy {
    case .none: break
    case .firstLine:
      guard let headers = try self._parseLine(rowIndex: 0) else { self.status = .finished; return }
      guard !headers.isEmpty else { throw Error._invalidEmptyHeader() }
      self.headers = headers
      self.count = (rows: 1, fields: headers.count)
    case let .lineNumber(index):
      // Parse rows, but ignore them
      for _ in 0..<index {
        _ = try self._parseLine(rowIndex: 0)
      }
      guard let headers = try self._parseLine(rowIndex: 0) else { self.status = .finished; return }
      guard !headers.isEmpty else { throw Error._invalidEmptyHeader() }
      self.headers = headers
      self.count = (rows: 1, fields: headers.count)
//    case .unknown: #warning("TODO")
    }
  }

  /// Index of the row to be parsed next (i.e. a row not yet parsed).
  ///
  /// This index is NOT offset by the existence of a header row. In other words:
  /// - If a CSV file has a header, the first row after a header (i.e. the first actual data row) will be the integer zero.
  /// - If a CSV file doesn't have a header, the first row to parse will also be zero.
  public var rowIndex: Int {
    let r = self.count.rows
    return self.headers.isEmpty ? r : r - 1
  }
}

extension CSVReader {
  /// Advances to the next row and returns it, or `nil` if no next row exists.
  /// - warning: If the CSV file being parsed contains invalid characters, this function will crash. For safer parsing use `readRow()` or `readRecord()`.
  /// - seealso: readRow()
  @inlinable public func next() -> [String]? {
    try! self.readRow()
  }

  /// Parses a CSV row and wraps it in a convenience structure giving accesses to fields through header titles/names.
  ///
  /// Since CSV parsing is sequential, if a previous call of this function encountered an error, subsequent calls will throw the same error.
  /// - throws: `CSVError<CSVReader>` exclusively.
  /// - returns: A record structure or `nil` if there isn't anything else to parse. If a record is returned there shall always be at least one field.
  /// - seealso: readRow()
  public func readRecord() throws -> Record? {
    guard let row = try self.readRow() else { return nil }

    let lookup: [Int:Int]
    if let l = self.headerLookup {
      lookup = l
    } else {
      lookup = try self.headers.lookupDictionary(onCollision: Error._invalidHashableHeader)
      self.headerLookup = lookup
    }

    return Record(row: row, lookup: lookup)
  }

  /// Parses a CSV row.
  ///
  /// Since CSV parsing is sequential, if a previous call of this function encountered an error, subsequent calls will throw the same error.
  /// - throws: `CSVError<CSVReader>` exclusively.
  /// - returns: The row's fields or `nil` if there isn't anything else to parse. The row will never be an empty array.
  public func readRow() throws -> [String]? {
    switch self.status {
    case .active: break
    case .finished: return nil
    case .failed(let e): throw e
    }

  loop: while true {
    let result: [String]?
    do {
      result = try self._parseLine(rowIndex: self.count.rows)
    } catch let error {
      self.status = .failed(error as! CSVError<CSVReader>)
      throw error
    }
    // If no fields were parsed, the EOF has been reached.
    guard let fields = result else {
      self.status = .finished
      return nil
    }

    let numFields = fields.count
    // If a single empty field is received, a white line has been parsed. Ignore empty lines for CSV files were several fields are expected.
    if numFields == 1, fields.first!.isEmpty, self.count.rows != 1 {
      continue loop
    }

    if self.count.rows > 0 {
      guard self.count.fields == numFields else {
        let error = Error._invalidFieldCount(rowIndex: self.count.rows+1, parsed: numFields, expected: self.count.fields)
        self.status = .failed(error)
        throw error
      }
    } else {
      self.count.fields = numFields
    }

    self.count.rows += 1
    return result
  }
  }
}

// MARK: -

extension CSVReader {
  /// Parses a CSV row.
  /// - parameter rowIndex: The current index location.
  /// - throws: `CSVError<CSVReader>` exclusively.
  /// - returns: The row's fields or `nil` if there isn't anything else to parse. The row will never be an empty array.
  private func _parseLine(rowIndex: Int) throws -> [String]? {
    var result: [String] = Array()
    result.reserveCapacity(self.count.fields)

    // 1. This loops starts a row, and then continue for every field.
  loop: while true {
    // 2. Try to retrieve a scalar (if there is none, we reached the EOF).
    guard let scalar = try self._scalarBuffer.next() ?? self._decoder() else {
      switch result.isEmpty {
      // 2.A. If no fields has been parsed, return nil.
      case true: return nil
      // 2.B. If there were previous fields, the EOF counts as en empty field (since there was no row delimiter previously).
      case false: result.append(""); break loop
      }
    }
    // 3. Check for characters to trim before a field is parsed.
    if self._settings.isTrimNeeded {
      // 3.1. If the character is within the trim character set, just ignore it.
      guard !self._settings.trimCharacters.contains(scalar) else { continue loop }
    }
    // 4. If the unicode scalar retrieved is the escaping scalar, an escaped field is awaiting parsing.
    if let escapingScalar = self._settings.escapingScalar, scalar == escapingScalar {
      let field = try self._parseEscapedField(rowIndex: rowIndex, escaping: escapingScalar)
      result.append(field.value)
      if field.isAtEnd { break loop }
    // 5. If the field delimiter is encountered, an implicit empty field has been defined.
    } else if try self._isFieldDelimiter(scalar) {
      result.append("")
    // 6. If the row delimiter is encountered, an implicit empty field has been defined (for rows that already have content).
    } else if try self._isRowDelimiter(scalar) {
      result.append("")
      break loop
    // 7. If a regular character is encountered, an "unescaped field" is awaiting parsing.
    } else {
      let field = try self._parseUnescapedField(starting: scalar, rowIndex: rowIndex)
      result.append(field.value)
      if field.isAtEnd { break loop }
    }
  }

    return result
  }

  /// Parses the awaiting unicode scalars expecting to form a "unescaped field".
  /// - parameter starting: The first regular scalar in the unescaped field.
  /// - parameter rowIndex: The index of the row being parsed.
  /// - throws: `CSVError<CSVReader>` exclusively.
  /// - returns: The parsed field and whether the row/file ending characters have been found.
  private func _parseUnescapedField(starting: Unicode.Scalar, rowIndex: Int) throws -> (value: String, isAtEnd: Bool) {
    var reachedRowsEnd = false
    self._fieldBuffer.append(starting)

    // 1. This loop continue parsing a unescaped field till the field end is reached.
    fieldLoop: while true {
      // 2. Try to retrieve an scalar (if not, it is the EOF).
      guard let scalar = try self._scalarBuffer.next() ?? self._decoder() else {
        reachedRowsEnd = true
        break fieldLoop
      }
      // 3. A escaping scalar cannot appear on unescaped fields. If one is encountered, an error is thrown.
      if scalar == self._settings.escapingScalar {
        throw Error._invalidUnescapedField(rowIndex: rowIndex)
      // 4. If the field delimiter is encountered, return the already parsed characters.
      } else if try self._isFieldDelimiter(scalar) {
        reachedRowsEnd = false
        break fieldLoop
      // 5. If the row delimiter is encountered, return the already parsed characters.
      } else if try self._isRowDelimiter(scalar) {
        reachedRowsEnd = true
        break fieldLoop
      // 6. If it is a regular unicode scalar, just store it and continue parsing.
      } else {
        self._fieldBuffer.append(scalar)
      }
    }
    // 7. Once the end has been reached, a field look-back (starting from the end) is performed to check if there are trim characters.
    if self._settings.isTrimNeeded {
      while let lastScalar = self._fieldBuffer.last, self._settings.trimCharacters.contains(lastScalar) {
        self._fieldBuffer.removeLast()
      }
    }

    let result = String(decoding: self._fieldBuffer.flatMap { UTF8.encode($0)! }, as: UTF8.self)
    self._fieldBuffer.removeAll()
    return (result, reachedRowsEnd)
  }

  /// Parses the awaiting unicode scalars expecting to form a "escaped field".
  ///
  /// When this function is executed, the quote opening the "escaped field" has already been read.
  /// - parameter rowIndex: The index of the row being parsed.
  /// - parameter escapingScalar: The unicode scalar escaping character to use.
  /// - throws: `CSVError<CSVReader>` exclusively.
  /// - returns: The parsed field and whether the row/file ending characters have been found.
  private func _parseEscapedField(rowIndex: Int, escaping escapingScalar: Unicode.Scalar) throws -> (value: String, isAtEnd: Bool) {
    var reachedRowsEnd = false

  fieldLoop: while true {
    // 1. Retrieve an scalar (if not there, it means EOF). This case is not allowed without closing the escaping field first.
    guard let scalar = try self._scalarBuffer.next() ?? self._decoder() else {
      throw Error._invalidEOF(rowIndex: rowIndex)
    }
    // 2. If the retrieved scalar is not the escaping scalar, just store it and continue parsing.
    guard scalar == escapingScalar else {
      self._fieldBuffer.append(scalar)
      continue fieldLoop
    }
    // 3. If the retrieved scalar was a escaping scalar, retrieve the following scalar and check if it is EOF. If so, the field has finished and also the row and the file.
    guard var followingScalar = try self._scalarBuffer.next() ?? self._decoder() else {
      reachedRowsEnd = true
      break fieldLoop
    }
    // 4. If the second retrieved scalar is another escaping scalar, the data is escaping the escaping scalar.
    guard followingScalar != escapingScalar else {
      self._fieldBuffer.append(escapingScalar)
      continue fieldLoop
    }
    // 5. Once this point is reached, the field has been properly escaped.
    if self._settings.isTrimNeeded {
      // 6. Trim any character after the quote if necessary.
      while self._settings.trimCharacters.contains(followingScalar) {
        guard let tmpScalar = try self._scalarBuffer.next() ?? self._decoder() else {
          reachedRowsEnd = true
          break fieldLoop
        }
        followingScalar = tmpScalar
      }
    }

    if try self._isFieldDelimiter(followingScalar) {
      break
    } else if try self._isRowDelimiter(followingScalar) {
      reachedRowsEnd = true
      break
    } else {
      let targetField = String(decoding: self._fieldBuffer.flatMap { UTF8.encode($0)! }, as: UTF8.self)
      throw Error._invalidEscapedField(rowIndex: rowIndex, field: targetField, nextScalar: followingScalar)
    }
  }

    let result = String(decoding: self._fieldBuffer.flatMap { UTF8.encode($0)! }, as: UTF8.self)
    self._fieldBuffer.removeAll()
    return (result, reachedRowsEnd)
  }
}

// MARK: -

fileprivate extension CSVReader.Error {
  /// Error raised when a header was required, but the line was empty.
  static func _invalidEmptyHeader() -> CSVError<CSVReader> {
    CSVError(.invalidConfiguration,
             reason: "A header line was expected, but an empty line was found instead.",
             help: "Make sure there is a header line at the very beginning of the file or mark the configuration as 'no header'.")
  }
  /// Error raised when a record is fetched, but there are header names which has the same hash value (i.e. they have the same name).
  static func _invalidHashableHeader() -> CSVError<CSVReader> {
    CSVError(.invalidInput,
             reason: "The header row contain two fields with the same value.",
             help: "Request a row instead of a record.")
  }
  /// Error raised when the number of fields are not kept constant between CSV rows.
  /// - parameter rowIndex: The location of the row which generated the error.
  /// - parameter parsed: The number of parsed fields.
  /// - parameter expected: The number of fields expected.
  static func _invalidFieldCount(rowIndex: Int, parsed: Int, expected: Int) -> CSVError<CSVReader> {
    CSVError(.invalidInput,
             reason: "The number of fields is not constant between rows.",
             help: "Make sure the CSV file has always the same amount of fields per row (including the header row).",
             userInfo: ["Row index": rowIndex,
                        "Number of parsed fields": parsed,
                        "Number of expected fields": expected])
  }
  /// Error raised when a unescape field finds a unescape quote within it.
  /// - parameter rowIndex: The location of the row which generated the error.
  static func _invalidUnescapedField(rowIndex: Int) -> CSVError<CSVReader> {
    CSVError(.invalidInput,
             reason: "The escaping scalar (double quotes by default) is not allowed within fields which aren't already escaped.",
             help: "Add the escaping scalar at the very beginning and the very end of the field and escape the escaping scalar found within the field.",
             userInfo: ["Row index": rowIndex])
  }
  /// Error raised when an EOF has been received but the last CSV field was not finalized.
  /// - parameter rowIndex: The location of the row which generated the error.
  static func _invalidEOF(rowIndex: Int) -> CSVError<CSVReader> {
    CSVError(.invalidInput,
             reason: "The last field is escaped (with double quotes if you haven't changed the defaults) and an EOF (End of File) was encountered before the field matched at the end with the closing escaping scalar.",
             help: "End the targeted field with the scaping scalar (double quotes by default).",
             userInfo: ["Row index": rowIndex])
  }
  /// Error raised when an escaped field hasn't been properly finalized.
  /// - parameter rowIndex: The location of the row which generated the error.
  /// - parameter field: The content of the escaped field.
  static func _invalidEscapedField(rowIndex: Int, field: String, nextScalar: Unicode.Scalar) -> CSVError<CSVReader> {
    CSVError(.invalidInput,
             reason: "The targeted field parsed successfully. However, the character right after it was not a field nor row delimiter.",
             help: (nextScalar == "\r") ? #"If your CSV is CRLF, change the row delimiter to "\r\n" or add a trim strategy for "\r"."# : "There seems to be some characters after the escaping character and before the next field or the end of the row. Please remove those.",
             userInfo: ["Row index": rowIndex, "Field": field])
  }
}
