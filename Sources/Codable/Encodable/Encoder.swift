/// Instances of this class are capable of encoding types into CSV files.
internal class CSVEncoder {
    /// Wrap all configurations in a single easy-to-use structure.
    private var configuration: Configuration
    /// A dictionary you use to customize the encoding process by providing contextual information.
    open var userInfo: [CodingUserInfoKey:Any] = [:]
    
    /// Designated initializer specifying default configuration values for the encoder.
    /// - parameter configuration: Optional configuration values for the encoding process.
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    /// Convenience initializer passing the most used configuration values.
    /// - parameter fieldDelimiter: The delimiter between CSV fields.
    /// - parameter rowDelimiter: The delimiter between CSV records/rows.
    /// - parameter headers: Indication on whether the CSV will contain a header row or not..
    public convenience init(fieldDelimiter: Delimiter.Field = ",", rowDelimiter: Delimiter.Row = "\n", headers: [String] = []) {
        self.init(configuration: .init(fieldDelimiter: fieldDelimiter, rowDelimiter: rowDelimiter, headers: headers))
    }
}
