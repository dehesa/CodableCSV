extension CSVReader {
    /// Structure wrapping over the result of a CSV file.
    ///
    /// When comparing two `FileView`s, only the rows are used (not the header names).
    public struct FileView: RandomAccessCollection, Equatable {
        /// A row representing the field titles/names.
        ///
        /// If empty, the file contained no headers.
        public let headers: [String]
        /// The CSV content (without the headers row).
        public let rows: [[String]]
        /// A lookup dictionary with the header name hash values as keys  and their corresponding field index.
        private let _lookup: [Int:Int]
        
        /// Creates a view to the passed CSV content.
        /// - parameter headers: The header row for the CSV content.
        /// - parameter rows: The CSV content.
        /// - parameter lookup: Look-up dictionary generated from the `headers` row.
        internal init(headers: [String], rows: [[String]], lookup: [Int:Int]) {
            self.headers = headers
            self.rows = rows
            self._lookup = lookup
        }
        
        /// Access the specified row at the given index.
        /// - precondition: `rowIndex` must be a valid index or the program will crash.
        /// - parameter rowIndex: Valid index pointing to the targeted row.
        public subscript(_ rowIndex: Int) -> [String] {
            self.rows[rowIndex]
        }
        
        /// Returns a view to the receiving CSV file, which can iterate over CSV records.
        public var records: RecordsView {
            .init(rows: self.rows, lookup: self._lookup)
        }
        
        /// Access the specified record at the given index.
        /// - precondition: `rowIndex` must be a valid index or the program will crash.
        /// - parameter rowIndex: Valid index pointing to the targeted row.
        @inline(__always) public subscript(record rowIndex: Int) -> Record {
            .init(row: self.rows[rowIndex], lookup: self._lookup)
        }
        
        /// Returns a view to the receiving CSV file, which can iterate over CSV columns.
        public var columns: ColumnsView {
            .init(file: self)
        }
        
        /// Returns all the fields under the given column index.
        /// - complexity: O(n)
        /// - precondition: `columnIndex` must be a valid index or the program will crash.
        /// - parameter columnIndex: Valid index pointing to the targeted column.
        public subscript(column columnIndex: Int) -> [String] {
            precondition(columnIndex < self.headers.count)
            return self.rows.map { $0[columnIndex] }
        }
        /// Returns all the fields under the given header name or `nil` if the passed header name is not in the headers row.
        /// - complexity: O(n)
        /// - parameter header: The header name/value of the targeted column.
        public subscript(column header: String) -> [String]? {
            guard let columnIndex = self._lookup[header.hashValue] else { return nil }
            return self[column: columnIndex]
        }
        
        /// Access the specified field at the given row.
        /// - precondition: `rowIndex` and `columnIndex` must be valid indeces or the program will crash.
        /// - parameter rowIndex: The index for the targeted row.
        /// - parameter columnIndex:The index for the targeted field.
        /// - returns: The field value as a `String` if the row contained such header.
        @inlinable public subscript(row rowIndex: Int, column columnIndex: Int) -> String {
            self.rows[rowIndex][columnIndex]
        }
        
        /// Access the specified field at the given row.
        /// - precondition: `rowIndex` must be a valid index or the program will crash.
        /// - parameter rowIndex: The index for the targeted row.
        /// - parameter header:The header title/name.
        /// - returns: The field value as a `String` if the row contained such header. Otherwise, `nil` is returned.
        public subscript(row rowIndex: Int, column header: String) -> String? {
            guard let columnIndex = self._lookup[header.hashValue] else { return nil }
            return self[row: rowIndex, column: columnIndex]
        }
        
        @_transparent public var startIndex: Int { self.rows.startIndex }
        @_transparent public var endIndex: Int { self.rows.endIndex }
        
        @_transparent public func index(after i: Int) -> Int { self.rows.index(after: i) }
        @_transparent public func index(before i: Int) -> Int { self.rows.index(before: i) }
        
        @_transparent public static func == (lhs: Self, rhs: Self) -> Bool { lhs.rows == rhs.rows }
        @_transparent public static func == (lhs: Self, rhs: [[String]]) -> Bool { lhs.rows == rhs }
    }
}

extension CSVReader.FileView {
    /// A view of a CSV file content as a collection of `CSVReader.Record` values.
    public struct RecordsView: RandomAccessCollection {
        /// The CSV content (without the headers row).
        private let _rows: [[String]]
        /// A lookup dictionary with the header name hash values as keys  and their corresponding field index.
        private let _lookup: [Int:Int]
        
        /// Creates a view iterating through the given CSV rows and the synthesized header lookup.
        fileprivate init(rows: [[String]], lookup: [Int:Int]) {
            self._rows = rows
            self._lookup = lookup
        }
        
        public var startIndex: Int { self._rows.startIndex }
        public var endIndex: Int { self._rows.endIndex }
        
        public func index(after i: Int) -> Int { self._rows.index(after: i) }
        public func index(before i: Int) -> Int { self._rows.index(before: i) }
        
        /// Returns the convenience `Record` structure wrapping over a CSV row.
        /// - precondition: `recordIndex` must be a valid index or the program will crash.
        /// - parameter recordIndex: The index for the targeted record/row.
        public subscript(_ recordIndex: Int) -> CSVReader.Record {
            precondition(recordIndex < self._rows.count)
            return .init(row: self._rows[recordIndex], lookup: self._lookup)
        }
    }
}

extension CSVReader.FileView {
    /// A view of a CSV file content as a collection of `CSVReader.Record` values.
    public struct ColumnsView: BidirectionalCollection {
        /// The _viewed_ CSV file.
        private let _file: CSVReader.FileView
        
        /// Creates a view iterating through the columns of the given CSV file.
        /// - parameter file: The file being _viewed_ by this convenience structure.
        fileprivate init(file: CSVReader.FileView) {
            self._file = file
        }
        
        public var startIndex: Int { self._file.headers.startIndex }
        public var endIndex: Int { self._file.headers.endIndex }
        
        public func index(after i: Int) -> Int { self._file.headers.index(after: i) }
        public func index(before i: Int) -> Int { self._file.headers.index(before: i) }
        
        /// Returns all the fields under the given column index.
        /// - complexity: O(n)
        /// - precondition: `columnIndex` must be a valid index or the program will crash.
        /// - parameter columnIndex: Valid index pointing to the targeted column.
        public subscript(_ columnIndex: Int) -> [String] { self._file[column: columnIndex] }
        /// Returns all the fields under the given header name or `nil` if the passed header name is not in the headers row.
        /// - complexity: O(n)
        /// - parameter header: The header name/value of the targeted column.
        public subscript(_ columnName: String) -> [String]? { self._file[column: columnName] }
    }
}

extension CSVReader {
    /// A record is a convenience structure on top of a CSV row (i.e. an array of strings) letting you access efficiently each field through its header title/name.
    public struct Record: RandomAccessCollection, Hashable {
        /// A CSV row content.
        public let row: [String]
        /// A lookup dictionary with the header name hash values as keys  and their corresponding field index.
        private let _lookup: [Int:Int]
        
        /// Designated initializer passing the required variables.
        internal init(row: [String], lookup: [Int:Int]) {
            self.row = row
            self._lookup = lookup
        }
        
        @_transparent public var startIndex: Int { self.row.startIndex }
        @_transparent public var endIndex: Int { self.row.endIndex }
        
        @_transparent public func index(after i: Int) -> Int { self.row.index(after: i) }
        @_transparent public func index(before i: Int) -> Int { self.row.index(before: i) }
        
        @_transparent public static func == (lhs: Self, rhs: Self) -> Bool { lhs.row == rhs.row }
        @_transparent public static func == (lhs: Self, rhs: [String]) -> Bool { lhs.row == rhs }
        @_transparent public func hash(into hasher: inout Hasher) { self.row.hash(into: &hasher) }
        
        /// Access the specified field at the given record.
        /// - precondition: `fieldIndex` must be a valid index or the program will crash.
        /// - parameter fieldIndex:The index for the targeted field.
        /// - returns: The field value as a `String` if the row contained such header.
        @inline(__always) public subscript(_ fieldIndex: Int) -> String {
            self.row[fieldIndex]
        }
        
        /// Accesses a row element given a header title/name.
        /// - parameter header: The header title/name.
        /// - returns: The field value as a `String` if the row contained such header. Otherwise, `nil` is returned.
        public subscript(_ header: String) -> String? {
            guard let index = self._lookup[header.hashValue] else { return nil }
            return self[index]
        }
    }
}
