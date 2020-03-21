//extension CSVWriter {
//    /// The states at which the `CSVWriter` can find itself at.
//    internal enum State {
//        /// File level state.
//        enum File {
//            /// The writer has been initialized, but no writing processes has been started yet.
//            case unbegun
//            /// The CSV file has been started and some data may have been already written to the output stream.
//            ///
//            /// `nextIndex` indicates the index of the row to write next.
//            case active(nextIndex: Int)
//            /// The CSV file has been closed, not allowing further data.
//            ///
//            /// `rowCount` indicate the number of rows that have been writen to.
//            case closed(rowCount: Int)
//
//            /// The number of rows FULLY writen so far.
//            var nextIndex: Int {
//                switch self {
//                case .unbegun: return 0
//                case .active(let count): return count
//                case .closed(let count): return count
//                }
//            }
//
//            /// Boolean indicating whether the file is active.
//            var isActive: Bool {
//                guard case .active = self else { return false }
//                return true
//            }
//        }
//
//        /// Row level state.
//        enum Row {
//            /// A new row hasn't been started yet.
//            case unstarted
//            /// The row has been started and `fields` amount of fields have been writen to it.
//            ///
//            /// `nextIndex` indicate the index of the field to write next.
//            case active(nextIndex: Int)
//
//            /// The number of fields FULLY writen so far.
//            var nextIndex: Int {
//                switch self {
//                case .unstarted: return 0
//                case .active(let fields): return fields
//                }
//            }
//        }
//    }
//}

extension CSVWriter {
    /// Indicates whether the [Byte Order Mark](https://en.wikipedia.org/wiki/Byte_order_mark) will be serialize with the date or not.
    public enum BOMSerialization {
        /// Includes the optional BOM at the beginning of the CSV representation for a small number of encodings.
        ///
        /// A BOM will only be included for the following cases (as specified in the stanrd):
        /// - `.utf16` and `.unicode`, in which case the BOM for UTF 16 Big endian encoding will be used.
        /// - `.utf32` in which ase the BOM for UTF 32 Big endian encoding will be used.
        /// - For any other case, no BOM will be written.
        case standard
        /// Always writes a BOM when possible (i.e. for Unicode encodings).
        case always
        /// Never writes a BOM.
        case never
    }
    
    /// The type of error raised by the CSV writer.
    public enum Error: Int {
        case invalidConfiguration = 1
        /// The output stream failed.
        case streamFailure = 4
    }
}

extension CSVWriter: Failable {
    public static var errorDomain: String { "Writer" }
    
    public static func errorDescription(for failure: Error) -> String {
        switch failure {
        case .invalidConfiguration: return "Invalid configuration"
        case .streamFailure: return "Stream failure"
        }
    }
}

//extension CSVWriter {
//    /// Errors that can be thrown from a CSV writer instance.
//    public enum Error: Swift.Error, CustomDebugStringConvertible {
//        /// The defined delimiter (whether field or row) was invalid. Please check the configuration.
//        case invalidDelimiter(String)
//        /// The pass String encoding is not supported at the moment.
//        case unsupportedEncoding(String.Encoding)
//        /// The output stream failed is some way. Please check the message for more information.
//        case outputStreamFailed(String, underlyingError: Swift.Error?)
//        /// The command given to the writer cannot be processed.
//        case invalidCommand(String)
//        /// The input couldn't be recognized or was `nil`.
//        case invalidInput(String)
//
//        public var debugDescription: String {
//            var result = "[CSVWriter] "
//            switch self {
//            case .invalidDelimiter(let message):
//                result.append("Invalid delimiter: ")
//                result.append(message)
//            case .unsupportedEncoding(let encoding):
//                result.append("Unsupported encoding: ")
//                result.append("The String encoding '\(encoding)' is not currently supported.")
//            case .outputStreamFailed(let message, let underlyingError):
//                result.append("Output stream failed: ")
//                result.append(message)
//                if let error = underlyingError {
//                    result.append("\nUnderlying Error: \(error)")
//                }
//            case .invalidCommand(let message):
//                result.append("Invalid command: ")
//                result.append(message)
//            case .invalidInput(let message):
//                result.append("Invalid input: ")
//                result.append(message)
//            }
//            return result
//        }
//    }
//}
