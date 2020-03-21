import Foundation

/// Instances of this class are capable of decoding CSV files as described by the `Codable` protocol.
@dynamicMemberLookup open class CSVDecoder {
    /// Wrap all configurations in a single easy-to-use structure.
    private final var configuration: Configuration
    /// A dictionary you use to customize the decoding process by providing contextual information.
    open var userInfo: [CodingUserInfoKey:Any] = [:]
    
    /// Creates a CSV decoder with tthe default configuration values.
    /// - parameter configuration: Configuration values for the decoding process.
    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }
    
    /// Returns a value of the type you specify, decoded from a CSV file (given as a `String`).
    /// - parameter type: The type of the value to decode from the supplied file.
    /// - parameter string: The file content to decode.
    /// - note: The encoding inferral process may take a lot of processing power if your data blo´b is big. Try to always input the encoding if you know it beforehand.
    open func decode<T:Decodable>(_ type: T.Type, from string: String) throws -> T {
        let reader: CSVReader = try CSVReader(input: string, configuration: self.configuration.readerConfiguration)
        let source = ShadowDecoder.Source(reader: reader, configuration: self.configuration, userInfo: self.userInfo)
        return try T(from: ShadowDecoder(source: source, codingPath: []))
    }

    /// Returns a value of the type you specify, decoded from a CSV file (given as a `Data` blob).
    /// - parameter type: The type of the value to decode from the supplied file.
    /// - parameter data: The file content to decode.
    /// - note: The encoding inferral process may take a lot of processing power if your data blob is big. Try to always input the encoding if you know it beforehand.
    open func decode<T:Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let reader: CSVReader = try CSVReader(input: data, configuration: self.configuration.readerConfiguration)
        let source = ShadowDecoder.Source(reader: reader, configuration: self.configuration, userInfo: self.userInfo)
        return try T(from: ShadowDecoder(source: source, codingPath: []))
    }
    
    /// Returns a value of the type you specify, decoded from a CSV file (given as a `String`).
    /// - parameter type: The type of the value to decode from the supplied file.
    /// - parameter string: The file content to decode.
    /// - note: The encoding inferral process may take a lot of processing power if your data blo´b is big. Try to always input the encoding if you know it beforehand.
    open func decode<T:Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let reader: CSVReader = try CSVReader(input: url, configuration: self.configuration.readerConfiguration)
        let source = ShadowDecoder.Source(reader: reader, configuration: self.configuration, userInfo: self.userInfo)
        return try T(from: ShadowDecoder(source: source, codingPath: []))
    }
}

extension CSVDecoder {
    /// Creates a CSV decoder with the configuration tweaked within the closure.
    /// - parameter configuration: A closure receiving the default configuration values and returning (by `inout`) a tweaked version of them.
    public convenience init(configuration: (inout Configuration)->Void) {
        var config = Configuration()
        configuration(&config)
        self.init(configuration: config)
    }
    
    /// Gives direct access to all the decoder's configuration values.
    /// - parameter member: Writable key path for the decoder's configuration value.
    public final subscript<V>(dynamicMember member: WritableKeyPath<CSVDecoder.Configuration,V>) -> V {
        get { self.configuration[keyPath: member] }
        set { self.configuration[keyPath: member] = newValue }
    }
}
