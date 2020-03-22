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
    /// The type of error raised by the CSV writer.
    public enum Error: Int {
        ///
        case invalidConfiguration = 1
        /// The output stream failed.
        case streamFailure = 4
        /// The operation couldn't be carried or failed midway.
        case invalidOperation = 5
    }
}

extension CSVWriter: Failable {
    public static var errorDomain: String { "Writer" }
    
    public static func errorDescription(for failure: Error) -> String {
        switch failure {
        case .invalidConfiguration: return "Invalid configuration"
        case .streamFailure: return "Stream failure"
        case .invalidOperation: return "Invalid Operation"
        }
    }
}
