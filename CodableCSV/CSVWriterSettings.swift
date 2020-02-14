import Foundation

extension CSVWriter {
    /// Specific configuration variables for the CSV writer.
    internal struct Settings {
        /// The unicode scalar delimiters for fields and rows.
        let delimiters: Delimiter.RawPair
        /// Boolean indicating whether the received CSV contains a header row or not.
        let headers: [String]
        /// The unicode scalar used as encapsulator and escaping character (when printed two times).
        let escapingScalar: Unicode.Scalar = Unicode.Scalar.quote
        
        /// Designated initializer taking generic CSV configuration (with possible unknown data) and making it specific to a CSV writer instance.
        /// - throws: `CSVWriter.Error` exclusively.
        init(configuration config: EncoderConfiguration) throws {
            self.delimiters.field = try Settings.validate(delimiter: config.delimiters.field, identifier: "field")
            self.delimiters.row = try Settings.validate(delimiter: config.delimiters.row, identifier: "row")
            self.headers = config.headers
        }
        
        /// Simple existance and non-emptiness validation for a delimiter.
        /// - parameter delimiter: The delimiter string representation.
        /// - parameter identifier: String indicating whether the delimiter is a field or a row delimiter.
        /// - throws: `CSVWriter.Error.invalidDelimiter` exclusively when the delimiters are not valid.
        /// - returns: The non-empty chain of unicode scalars.
        private static func validate(delimiter: StringRepresentable, identifier: String) throws -> String.UnicodeScalarView {
            guard let view = delimiter.unicodeScalars else {
                throw Error.invalidDelimiter(message: "The \(identifier) delimiter is unknown. A CSV writer pass cannot be executed without a properly defined \(identifier) delimiter.")
            }
            
            guard !view.isEmpty else {
                throw Error.invalidDelimiter(message: "The custom \(identifier) delimiter is empty. A CSV writer pass cannot be executed without a properly defined \(identifier) delimiter.")
            }
            
            return view
        }
    }
}

extension CSVWriter {
    /// The states at which the `CSVWriter` can find itself at.
    internal enum State {
        /// File level state.
        internal enum File {
            /// The writer has been initialized, but no writing processes has been started yet.
            case unbegun
            /// The CSV file has been started and some data may have been already written to the output stream.
            ///
            /// `nextIndex` indicates the index of the row to write next.
            case active(nextIndex: Int)
            /// The CSV file has been closed, not allowing further data.
            ///
            /// `rowCount` indicate the number of rows that have been writen to.
            case closed(rowCount: Int)
            
            /// The number of rows FULLY writen so far.
            var nextIndex: Int {
                switch self {
                case .unbegun: return 0
                case .active(let count): return count
                case .closed(let count): return count
                }
            }
            
            /// Boolean indicating whether the file is active.
            var isActive: Bool {
                guard case .active = self else { return false }
                return true
            }
        }
        
        /// Row level state.
        internal enum Row {
            /// A new row hasn't been started yet.
            case unstarted
            /// The row has been started and `fields` amount of fields have been writen to it.
            ///
            /// `nextIndex` indicate the index of the field to write next.
            case active(nextIndex: Int)
            
            /// The number of fields FULLY writen so far.
            var nextIndex: Int {
                switch self {
                case .unstarted: return 0
                case .active(let fields): return fields
                }
            }
        }
    }
}
