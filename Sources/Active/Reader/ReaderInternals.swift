extension CSVReader {
    /// Reader status indicating whether there are remaning lines to read, the CSV has been completely parsed, or an error occurred and no further operation shall be performed.
    public enum Status {
        /// The CSV file hasn't been completely parsed.
        case active
        /// There are no more rows to read. The EOF has been reached.
        case finished
        /// An error has occurred and no further operations shall be performed with the reader instance.
        case failed(CSVError<CSVReader>)
    }
    
    /// The type of error raised by the CSV reader.
    public enum Error: Int {
        /// Some of the configuration values provided are invalid.
        case invalidConfiguration = 1
        /// The CSV data is invalid.
        case invalidInput = 2
//        /// The inferral process to figure out delimiters or header row status was unsuccessful.
//        case inferenceFailure = 3
        /// The input stream failed.
        case streamFailure = 4
    }
}

extension CSVReader: Failable {
    public static var errorDomain: String { "Reader" }
    
    public static func errorDescription(for failure: Error) -> String {
        switch failure {
        case .invalidConfiguration: return "Invalid configuration"
//        case .inferenceFailure: return "Inference failure"
        case .invalidInput: return "Invalid input"
        case .streamFailure: return "Stream failure"
        }
    }
}

extension CSVReader {
    /// A record is a convenience structure on top of a CSV row (i.e. an array of strings) letting you access efficiently each field through its header title/name.
    public struct Record: RandomAccessCollection, Hashable {
        /// A CSV row content.
        public let row: [String]
        /// A lookup dictionary with the header name hash values as keys  and their corresponding field index.
        private let lookup: [Int:Int]
        
        /// Designated initializer passing the required variables.
        internal init(row: [String], lookup: [Int:Int]) {
            self.row = row
            self.lookup = lookup
        }
        
        /// Accesses a row element given a header title/name.
        /// - parameter field: The header title/name.
        /// - returns: The field value as a `String` if the row contained such header. Otherwise, `nil` is returned.
        public subscript(_ field: String) -> String? {
            guard let index = self.lookup[field.hashValue] else { return nil }
            return self[index]
        }
        
        // Sequence adoption
        @_transparent public func makeIterator() -> IndexingIterator<[String]> { self.row.makeIterator() }
        // Collection adoption
        @_transparent public var startIndex: Int { self.row.startIndex }
        @_transparent public var endIndex: Int { self.row.endIndex }
        @_transparent public func index(after i: Int) -> Int { self.row.index(after: i) }
        @inline(__always) public subscript(_ index: Int) -> String { self.row[index] }
        // BidirectionalCollection adoption
        @_transparent public func index(before i: Int) -> Int { self.row.index(before: i) }
        // Hashable adoption
        @_transparent public func hash(into hasher: inout Hasher) { self.row.hash(into: &hasher) }
        // Equatable adoption
        @_transparent public static func == (lhs: Self, rhs: Self) -> Bool { lhs.row == rhs.row }
        @_transparent public static func == (lhs: Self, rhs: [String]) -> Bool { lhs.row == rhs }
    }
    
    /// Structure wrapping over the result of a CSV file.
    public struct Output: RandomAccessCollection, Equatable {
        /// A row representing the field titles/names.
        public let headers: [String]
        /// The CSV content (without the headers row).
        public let rows: [[String]]
        /// A lookup dictionary with the header name hash values as keys  and their corresponding field index.
        private let lookup: [Int:Int]
        
        /// Designated initializer passing all the required variables.
        internal init(headers: [String], rows: [[String]], lookup: [Int:Int]) {
            self.headers = headers
            self.rows = rows
            self.lookup = lookup
        }
        
        /// Access the specified field at the given row.
        /// - parameter rowIndex: The index for the targeted row.
        /// - parameter field:The header title/name.
        /// - returns: The field value as a `String` if the row contained such header. Otherwise, `nil` is returned.
        public subscript(row rowIndex: Int, field: String) -> String? {
            guard let fieldIndex = self.lookup[field.hashValue] else { return nil }
            return self[row: rowIndex, field: fieldIndex]
        }
        /// Access the specified field at the given row.
        /// - parameter rowIndex: The index for the targeted row.
        /// - parameter fieldIndex:The index for the targeted field.
        /// - returns: The field value as a `String` if the row contained such header. Otherwise, `nil` is returned.
        @inlinable public subscript(row rowIndex: Int, field fieldIndex: Int) -> String { self.rows[rowIndex][fieldIndex] }
        
        // Sequence adoption
        public func makeIterator() -> Iterator { Iterator(output: self) }
        // Collection adoption
        @_transparent public var startIndex: Int { self.rows.startIndex }
        @_transparent public var endIndex: Int { self.rows.endIndex }
        @_transparent public func index(after i: Int) -> Int { self.rows.index(after: i) }
        @inline(__always) public subscript(_ rowIndex: Int) -> Record { .init(row: self.rows[rowIndex], lookup: self.lookup) }
        // BidirectionCollection adoption
        @_transparent public func index(before i: Int) -> Int { self.rows.index(before: i) }
        // Equatable adoption
        @_transparent public static func == (lhs: Self, rhs: Self) -> Bool { lhs.rows == rhs.rows }
        @_transparent public static func == (lhs: Self, rhs: [[String]]) -> Bool { lhs.rows == rhs }
    }
}

extension CSVReader.Output {
    /// Custom iterator used
    public struct Iterator: IteratorProtocol {
        /// The view to the CSV file.
        private let output: CSVReader.Output
        /// The record to fetch next.
        private var nextIndex: Int
        
        /// Designated initializer passing all the required variables.
        fileprivate init(output: CSVReader.Output) {
            self.output = output
            self.nextIndex = 0
        }
        
        public mutating func next() -> CSVReader.Record? {
            guard self.output.rows.endIndex > self.nextIndex else { return nil }
            defer { self.nextIndex += 1 }
            return self.output[self.nextIndex]
        }
    }
}
