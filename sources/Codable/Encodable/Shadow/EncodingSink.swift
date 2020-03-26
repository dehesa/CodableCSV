extension ShadowEncoder {
    /// Sink of all CSV data.
    internal final class Sink {
        /// The instance writing the CSV data.
        private let writer: CSVWriter
        /// The decoding configuration.
        let configuration: CSVEncoder.Configuration
        /// Any contextual information set by the user for decoding.
        let userInfo: [CodingUserInfoKey:Any]
        
        /// Creates the unique data sink for the encoding process.
        init(writer: CSVWriter, configuration: CSVEncoder.Configuration, userInfo: [CodingUserInfoKey:Any]) {
            self.writer = writer
            self.configuration = configuration
            self.userInfo = userInfo
        }
    }
}
