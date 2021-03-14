import Foundation

extension CSVReader {
    /// Creates a reader instance that will be used to parse the given `String`.
    /// - parameter input: A `String`-like argument containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    public convenience init<S>(input: S, configuration: Configuration = .init()) throws where S:StringProtocol {
        let buffer = ScalarBuffer(reservingCapacity: 8)
        let decoder = CSVReader.makeDecoder(from: input.unicodeScalars.makeIterator())
        try self.init(configuration: configuration, buffer: buffer, decoder: decoder)
    }

    /// Creates a reader instance that will be used to parse the given data blob.
    ///
    /// If the configuration's encoding hasn't been set and the input data doesn't contain a Byte Order Marker (BOM), UTF8 is presumed.
    /// - parameter input: A data blob containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    public convenience init(input: Data, configuration: Configuration = .init()) throws {
        if configuration.presample, let dataEncoding = configuration.encoding {
            // A. If the `presample` configuration has been set and the user has explicitly marked an encoding, then the data can parsed into a string.
            guard let string = String(data: input, encoding: dataEncoding) else { throw Error._mismatched(encoding: dataEncoding) }
            try self.init(input: string, configuration: configuration)
        } else {
            // B. Otherwise, start parsing byte-by-byte.
            let buffer = ScalarBuffer(reservingCapacity: 8)
            // B.1. Check whether the input data has a BOM.
            var dataIterator = input.makeIterator()
            let (inferredEncoding, unusedBytes) = String.Encoding.infer(from: &dataIterator)
            // B.2. Select the appropriate encoding depending from the user provided encoding (if any), and the BOM encoding (if any).
            let encoding = try CSVReader.selectEncodingFrom(provided: configuration.encoding, inferred: inferredEncoding)
            // B.3. Create the scalar iterator producing all `Unicode.Scalar`s from the data bytes.
            let decoder = try CSVReader.makeDecoder(from: dataIterator, encoding: encoding, firstBytes: unusedBytes)
            try self.init(configuration: configuration, buffer: buffer, decoder: decoder)
        }
    }

    /// Creates a reader instance that will be used to parse the given CSV file.
    ///
    /// If the configuration's encoding hasn't been set and the input data doesn't contain a Byte Order Marker (BOM), UTF8 is presumed.
    /// - parameter input: The URL indicating the location of the file to be parsed.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    public convenience init(input: URL, configuration: Configuration = .init()) throws {
        // A. If the `presample` configuration has been set, the file can be completely loaded into memory.
        if configuration.presample {
            let data: Data
            do {
                data = try Data(contentsOf: input) /*, options: .uncached)*/
            } catch let error {
                throw Error._invalidData(fileURL: input, underlying: error)
            }
            try self.init(input: data, configuration: configuration)
        // B. Otherwise, create an input stream and start parsing byte-by-byte.
        } else {
            guard let stream = InputStream(url: input) else { throw Error._invalidStream(fileURL: input) }
            try self.init(stream: stream, configuration: configuration)
        }
    }

    /// Creates a reader instance that will be used to parse the given CSV stream.
    ///
    /// If the configuration's encoding hasn't been set and the input data doesn't contain a Byte Order Marker (BOM), UTF8 is presumed.
    /// - parameter input: The stream to be parsed.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    public convenience init(input: InputStream, configuration: Configuration = .init()) throws {
         // A. If the `presample` configuration has been set, the file can be completely loaded into memory.
        if configuration.presample {
            let data: Data
            do {
                data = try Data(stream: input, chunk: 1024)
            } catch let error {
                throw Error._invalidData(stream: input, underlying: error)
            }
            try self.init(input: data, configuration: configuration)
        // B. Otherwise, read from the input stream byte-by-byte.
        } else {
            try self.init(stream: input, configuration: configuration)
        }
    }
}

extension CSVReader {
    /// Creates a reader instance that will be used to parse the given `String`.
    /// - parameter input: A `String`-like argument containing CSV formatted data.
    /// - parameter setter: Closure receiving the default parsing configuration values and letting you  change them.
    /// - parameter configuration: Default configuration values for the `CSVReader`.
    /// - throws: `CSVError<CSVReader>` exclusively.
    @inlinable public convenience init<S>(input: S, setter: (_ configuration: inout Configuration)->Void) throws where S:StringProtocol {
        var configuration = Configuration()
        setter(&configuration)
        try self.init(input: input, configuration: configuration)
    }

    /// Creates a reader instance that will be used to parse the given data blob.
    /// - parameter input: A data blob containing CSV formatted data.
    /// - parameter setter: Closure receiving the default parsing configuration values and letting you  change them.
    /// - parameter configuration: Default configuration values for the `CSVReader`.
    /// - throws: `CSVError<CSVReader>` exclusively.
    @inlinable public convenience init(input: Data, setter: (_ configuration: inout Configuration)->Void) throws {
        var configuration = Configuration()
        setter(&configuration)
        try self.init(input: input, configuration: configuration)
    }

    /// Creates a reader instance that will be used to parse the given CSV file.
    /// - parameter input: The URL indicating the location of the file to be parsed.
    /// - parameter setter: Closure receiving the default parsing configuration values and letting you  change them.
    /// - parameter configuration: Default configuration values for the `CSVReader`.
    /// - throws: `CSVError<CSVReader>` exclusively.
    @inlinable public convenience init(input: URL, setter: (_ configuration: inout Configuration)->Void) throws {
        var configuration = Configuration()
        setter(&configuration)
        try self.init(input: input, configuration: configuration)
    }

    /// Creates a reader instance that will be used to parse the given CSV stream.
    /// - parameter input: The stream type to be parsed.
    /// - parameter setter: Closure receiving the default parsing configuration values and letting you  change them.
    /// - parameter configuration: Default configuration values for the `CSVReader`.
    /// - throws: `CSVError<CSVReader>` exclusively.
    @inlinable public convenience init(input: InputStream, setter: (_ configuration: inout Configuration)->Void) throws {
        var configuration = Configuration()
        setter(&configuration)
        try self.init(input: input, configuration: configuration)
    }
}

// MARK: -

extension CSVReader {
    /// Reads the Swift String and returns the CSV headers (if any) and all the records.
    /// - parameter input: A `String`-like argument containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Structure containing all CSV rows and optionally a the CSV headers.
    public static func decode<S>(input: S, configuration: Configuration = .init()) throws -> FileView where S:StringProtocol {
        let reader = try CSVReader(input: input, configuration: configuration)
        return try reader._decodeFile()
    }

    /// Reads a blob of data using the encoding provided as argument and returns the CSV headers (if any) and all the CSV records.
    /// - parameter input: A blob of data containing CSV formatted data.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Structure containing all CSV rows and optionally a the CSV headers.
    public static func decode(input: Data, configuration: Configuration = .init()) throws -> FileView {
        let reader = try CSVReader(input: input, configuration: configuration)
        return try reader._decodeFile()
    }

    /// Reads a CSV file using the provided encoding and returns the CSV headers (if any) and all the CSV records.
    /// - parameter input: The URL indicating the location of the file to be parsed.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. delimiters, date strategy, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Structure containing all CSV rows and optionally a the CSV headers.
    public static func decode(input: URL, configuration: Configuration = .init()) throws -> FileView {
        let reader = try CSVReader(input: input, configuration: configuration)
        return try reader._decodeFile()
    }
    
    /// Reads a CSV file using the provided encoding and returns the CSV headers (if any) and all the CSV records.
    /// - parameter input: The stream to be parsed.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Structure containing all CSV rows and optionally a the CSV headers.
    public static func decode(input: InputStream, configuration: Configuration = .init()) throws -> FileView {
        let reader = try CSVReader(input: input, configuration: configuration)
        return try reader._decodeFile()
    }
}

extension CSVReader {
    /// Reads the Swift String and returns the CSV headers (if any) and all the records.
    /// - parameter input: A `String` value containing CSV formatted data.
    /// - parameter setter: Closure receiving the default parsing configuration values and letting you  change them.
    /// - parameter configuration: Default configuration values for the `CSVReader`.
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Structure containing all CSV rows and optionally a the CSV headers.
    @inlinable public static func decode<S>(input: S, setter: (_ configuration: inout Configuration)->Void) throws -> FileView where S:StringProtocol {
        var configuration = Configuration()
        setter(&configuration)
        return try CSVReader.decode(input: input, configuration: configuration)
    }

    /// Reads a blob of data using the encoding provided as argument and returns the CSV headers (if any) and all the CSV records.
    /// - parameter input: A blob of data containing CSV formatted data.
    /// - parameter setter: Closure receiving the default parsing configuration values and letting you  change them.
    /// - parameter configuration: Default configuration values for the `CSVReader`.
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Structure containing all CSV rows and optionally a the CSV headers.
    @inlinable public static func decode(input: Data, setter: (_ configuration: inout Configuration)->Void) throws -> FileView {
        var configuration = Configuration()
        setter(&configuration)
        return try CSVReader.decode(input: input, configuration: configuration)
    }

    /// Reads a CSV file using the provided encoding and returns the CSV headers (if any) and all the CSV records.
    /// - parameter input: The URL indicating the location of the file to be parsed.
    /// - parameter setter: Closure receiving the default parsing configuration values and letting you  change them.
    /// - parameter configuration: Default configuration values for the `CSVReader`. 
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Structure containing all CSV rows and optionally a the CSV headers.
    @inlinable public static func decode(input: URL, setter: (_ configuration: inout Configuration)->Void) throws -> FileView {
        var configuration = Configuration()
        setter(&configuration)
        return try CSVReader.decode(input: input, configuration: configuration)
    }
    
    /// Reads a CSV file using the provided encoding and returns the CSV headers (if any) and all the CSV records.
    /// - parameter input: The stream to be parsed.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Structure containing all CSV rows and optionally a the CSV headers.
    @inlinable public static func decode(input: InputStream, setter: (_ configuration: inout Configuration)->Void) throws -> FileView {
        var configuration = Configuration()
        setter(&configuration)
        return try CSVReader.decode(input: input, configuration: configuration)
    }
}

// MARK: -

private extension CSVReader {
    /// Creates a reader instance that will be used to parse the given CSV stream.
    /// - precondition: The configuration `presample` value is false.
    /// - parameter stream: The stream to be parsed.
    /// - parameter configuration: Recipe detailing how to parse the CSV data (i.e. encoding, delimiters, etc.).
    /// - throws: `CSVError<CSVReader>` exclusively.
    private convenience init(stream: InputStream, configuration: Configuration) throws {
        assert(!configuration.presample && stream.streamStatus == .notOpen)
        stream.open()
        
        let (encoding, unusedBytes): (String.Encoding, [UInt8])
        do { // B.2. Check whether the input data has a BOM.
            let inferred = try String.Encoding.infer(from: stream)
            // B.3. Select the appropriate encoding depending from the user provided encoding (if any), and the BOM encoding (if any).
            encoding = try CSVReader.selectEncodingFrom(provided: configuration.encoding, inferred: inferred.encoding)
            unusedBytes = inferred.unusedBytes
        } catch let error {
            if stream.streamStatus != .closed { stream.close() }
            throw error
        }
        
        // B.5. Create the scalar buffer & iterator producing all `Unicode.Scalar`s from the data bytes.
        let buffer = ScalarBuffer(reservingCapacity: 8)
        let decoder = try CSVReader.makeDecoder(from: stream, encoding: encoding, chunk: 1024, firstBytes: unusedBytes)
        try self.init(configuration: configuration, buffer: buffer, decoder: decoder)
    }
    
    /// Use the provided reader to completely read a CSV and returns the CSV headers (if any) and all the CSV records.
    /// - parameter reader: The `CSVReader` used for parsing a CSV input.
    /// - throws: `CSVError<CSVReader>` exclusively.
    /// - returns: Structure containing all CSV rows and optionally a the CSV headers.
    private func _decodeFile() throws -> FileView {
        let lookup = try self.headers.lookupDictionary(onCollision: Error._invalidHashableHeader)
        
        var result: [[String]] = .init()
        while let row = try self.readRow() {
            result.append(row)
        }
        
        return .init(headers: self.headers, rows: result, lookup: lookup)
    }
}

fileprivate extension CSVReader.Error {
    /// Error raised when the given `String.Encoding` is not supported by the library.
    /// - parameter encoding: The desired byte representatoion.
    static func _mismatched(encoding: String.Encoding) -> CSVError<CSVReader> {
        .init(.invalidConfiguration,
              reason: "The data blob didn't match the given string encoding.",
              help: "Let the reader infer the encoding or make sure the data blob is correctly formatted.",
              userInfo: ["Encoding": encoding])
    }
    /// Error raised when a file URL cannot be read into a data blob.
    /// - parameter fileURL: The URL address of the invalid file.
    /// - parameter underlying: The underlying error thrown by the `Data` API.
    static func _invalidData(fileURL: URL, underlying: Swift.Error) -> CSVError<CSVReader> {
        .init(.invalidInput, underlying: underlying,
              reason: "The file under the given URL couldn't be read.",
              help: "Make sure the URL is valid and you are allowed to access the file.",
              userInfo: ["File URL": fileURL])
    }
    /// Error raised when an input stream cannot be created to the indicated file URL.
    /// - parameter fileURL: The URL address of the invalid file.
    static func _invalidStream(fileURL: URL) -> CSVError<CSVReader> {
        .init(.streamFailure,
              reason: "Creating an input stream to the given file URL failed.",
              help: "Make sure the URL is valid and you are allowed to access the file. Alternatively set the configuration's presample or load the file in a data blob and use the reader's data initializer.",
              userInfo: ["File URL": fileURL])
    }
    /// Error raised when the input stream couldn't be fully read.
    /// - parameter stream: The given input stream.
    /// - parameter underlying: The underlying error thrown by the input stream.
    static func _invalidData(stream: InputStream, underlying: Swift.Error) -> CSVError<CSVReader> {
        .init(.streamFailure, underlying: underlying,
              reason: "The provided input stream could not be read in its entirety.",
              help: "Make sure there is data in the input stream and that you have access to it.",
              userInfo: ["Input stream": stream])
    }
    /// Error raised when a record is fetched, but there are header names which has the same hash value (i.e. they have the same name).
    static func _invalidHashableHeader() -> CSVError<CSVReader> {
        .init(.invalidInput,
              reason: "The header row contain two fields with the same value.",
              help: "Request a row instead of a record.")
    }
}
