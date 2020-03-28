extension Strategy {
    /// Indicates whether the [Byte Order Mark](https://en.wikipedia.org/wiki/Byte_order_mark) will be serialize with the date or not.
    public enum BOM {
        /// Includes the optional BOM at the beginning of the CSV representation for a small number of encodings.
        ///
        /// A BOM will only be included for the following cases (as specified in the standard):
        /// - `.utf16` and `.unicode`, in which case the BOM for UTF 16 Big endian encoding will be used.
        /// - `.utf32` in which ase the BOM for UTF 32 Big endian encoding will be used.
        /// - For any other case, no BOM will be written.
        case convention
        /// Always writes a BOM when possible (i.e. for Unicode encodings).
        case always
        /// Never writes a BOM.
        case never
    }
}

extension CSVWriter: Failable {
    /// The type of error raised by the CSV writer.
    public enum Error: Int {
        /// Some of the configuration values provided are invalid.
        case invalidConfiguration = 1
        /// The CSV data is invalid.
        case invalidInput = 2
        /// The output stream failed.
        case streamFailure = 4
        /// The operation couldn't be carried or failed midway.
        case invalidOperation = 5
    }

    public static var errorDomain: String { "Writer" }
    
    public static func errorDescription(for failure: Error) -> String {
        switch failure {
        case .invalidConfiguration: return "Invalid configuration"
        case .invalidInput: return "Invalid input"
        case .streamFailure: return "Stream failure"
        case .invalidOperation: return "Invalid operation"
        }
    }
}
