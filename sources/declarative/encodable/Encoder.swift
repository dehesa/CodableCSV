import Foundation

/// Instances of this class are capable of encoding types into CSV files.
@dynamicMemberLookup public class CSVEncoder {
    /// Wrap all configurations in a single easy-to-use structure.
    private final var _configuration: Configuration
    /// A dictionary you use to customize the encoding process by providing contextual information.
    open var userInfo: [CodingUserInfoKey:Any]
    
    /// Creates a CSV encoder with the default configuration values.
    /// - parameter configuration: Optional configuration values for the encoding process.
    public init(configuration: Configuration = .init()) {
        self._configuration = configuration
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
        get { self._configuration[keyPath: member] }
        set { self._configuration[keyPath: member] = newValue }
    }
}

extension CSVEncoder {
    /// Returns a CSV-encoded representation of the value you supply.
    /// - parameter value: The value to encode as CSV.
    /// - parameter type: The Swift type for a data blob.
    /// - returns: `Data` blob with the CSV representation of `value`.
    open func encode<T:Encodable>(_ value: T, into type: Data.Type) throws -> Data {
        let writer = try CSVWriter(configuration: self._configuration.writerConfiguration)
        try withExtendedLifetime(try ShadowEncoder.Sink(writer: writer, configuration: self._configuration, userInfo: self.userInfo)) {
            try value.encode(to: ShadowEncoder(sink: .passUnretained($0), codingPath: []))
            try $0.completeEncoding()
        }
        return try writer.data()
    }
    
    /// Returns a CSV-encoded representation of the value you supply.
    /// - parameter value: The value to encode as CSV.
    /// - parameter type: The Swift type for a string.
    /// - returns: `String` with the CSV representation of `value`.
    open func encode<T:Encodable>(_ value: T, into type: String.Type) throws -> String {
        let data = try self.encode(value, into: Data.self)
        let encoding = self._configuration.writerConfiguration.encoding ?? .utf8
        return String(data: data, encoding: encoding)!
    }
    
    /// Returns a CSV-encoded representation of the value you supply.
    /// - parameter value: The value to encode as CSV.
    /// - parameter fileURL: The file receiving the encoded values.
    /// - parameter append: In case an existing file is under the given URL, this Boolean indicates that the information will be appended to the file (`true`), or the file will be overwritten (`false`).
    open func encode<T:Encodable>(_ value: T, into fileURL: URL, append: Bool = false) throws {
        let writer = try CSVWriter(fileURL: fileURL, append: append, configuration: self._configuration.writerConfiguration)
        try withExtendedLifetime(try ShadowEncoder.Sink(writer: writer, configuration: self._configuration, userInfo: self.userInfo)) {
            try value.encode(to: ShadowEncoder(sink: .passUnretained($0), codingPath: []))
            try $0.completeEncoding()
        }
    }
}

extension CSVEncoder {
    /// Returns an instance to encode row-by-row the feeded values.
    /// - parameter type: The Swift type for a data blob.
    /// - returns: Instance used for _on demand_ encoding.
    open func lazy(into type: Data.Type) throws -> Lazy<Data> {
        let writer = try CSVWriter(configuration: self._configuration.writerConfiguration)
        let sink = try ShadowEncoder.Sink(writer: writer, configuration: self._configuration, userInfo: self.userInfo)
        return Lazy<Data>(sink: sink)
    }
    
    /// Returns an instance to encode row-by-row the feeded values.
    /// - parameter type: The Swift type for a data blob.
    /// - returns: Instance used for _on demand_ encoding.
    open func lazy(into type: String.Type) throws -> Lazy<String> {
        let writer = try CSVWriter(configuration: self._configuration.writerConfiguration)
        let sink = try ShadowEncoder.Sink(writer: writer, configuration: self._configuration, userInfo: self.userInfo)
        return Lazy<String>(sink: sink)
    }
    
    /// Returns an instance to encode row-by-row the feeded values.
    /// - parameter fileURL: The file receiving the encoded values.
    /// - parameter append: In case an existing file is under the given URL, this Boolean indicates that the information will be appended to the file (`true`), or the file will be overwritten (`false`).
    /// - returns: Instance used for _on demand_ encoding.
    open func lazy(into fileURL: URL, append: Bool = false) throws -> Lazy<URL> {
        let writer = try CSVWriter(fileURL: fileURL, append: append, configuration: self._configuration.writerConfiguration)
        let sink = try ShadowEncoder.Sink(writer: writer, configuration: self._configuration, userInfo: self.userInfo)
        return Lazy<URL>(sink: sink)
    }
}

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CSVEncoder: TopLevelEncoder {
    public typealias Output = Data
    
    @inlinable public func encode<T:Encodable>(_ value: T) throws -> Data {
        try self.encode(value, into: Data.self)
    }
}
#endif
