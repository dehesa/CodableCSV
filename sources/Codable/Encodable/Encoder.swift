import Foundation

/// Instances of this class are capable of encoding types into CSV files.
@dynamicMemberLookup internal class CSVEncoder {
    /// Wrap all configurations in a single easy-to-use structure.
    private final var configuration: Configuration
    /// A dictionary you use to customize the encoding process by providing contextual information.
    open var userInfo: [CodingUserInfoKey:Any]
    
    /// Creates a CSV encoder with the default configuration values.
    /// - parameter configuration: Optional configuration values for the encoding process.
    public init(configuration: Configuration) {
        self.configuration = configuration
        self.userInfo = .init()
    }
    
    /// Creates a CSV encoder and passes the default configuration values to the closure.
    /// - parameter configuration: A closure receiving the default configuration values and returning (by `inout`) a tweaked version of them.
    @inlinable public convenience init(configuration: (inout Configuration)->Void) {
        var config = Configuration()
        configuration(&config)
        self.init(configuration: config)
    }
    
    /// Gives direct access to all the encoder's configuration values.
    /// - parameter member: Writable key path for the decoder's configuration value.
    public final subscript<V>(dynamicMember member: WritableKeyPath<CSVEncoder.Configuration,V>) -> V {
        get { self.configuration[keyPath: member] }
        set { self.configuration[keyPath: member] = newValue }
    }
}

extension CSVEncoder {
    /// Returns a CSV-encoded representation of the value you supply.
    /// - parameter value: The value to encode as CSV.
    /// - returns: `Data` blob with the CSV representation of `value`.
    open func encode<T:Encodable>(_ value: T) throws -> Data {
        let writer = try CSVWriter(configuration: self.configuration.writerConfiguration)
        let sink = ShadowEncoder.Sink(writer: writer, configuration: self.configuration, userInfo: self.userInfo)
        try value.encode(to: ShadowEncoder(sink: sink, codingPath: []))
        try writer.endFile()
        return try writer.data()
    }
    
    /// Returns a CSV-encoded representation of the value you supply.
    /// - parameter value: The value to encode as CSV.
    /// - returns: `String` with the CSV representation of `value`.
    open func encode<T:Encodable>(_ value: T, into: String.Type) throws -> String {
        let data = try self.encode(value)
        return String(data: data, encoding: self.configuration.writerConfiguration.encoding ?? .utf8)!
    }
    
    /// Returns a CSV-encoded representation of the value you supply.
    /// - parameter value: The value to encode as CSV.
    /// - parameter fileURL: The file receiving the encoded values.
    open func encode<T:Encodable>(_ value: T, into fileURL: URL, append: Bool) throws {
        let writer = try CSVWriter(fileURL: fileURL, append: append, configuration: self.configuration.writerConfiguration)
        let sink = ShadowEncoder.Sink(writer: writer, configuration: self.configuration, userInfo: self.userInfo)
        try value.encode(to: ShadowEncoder(sink: sink, codingPath: []))
        try writer.endFile()
    }
}
