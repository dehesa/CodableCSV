import Foundation

extension CSVWriter {
    /// Creates a writer instance that will be used to encode CSV-formatted data into a `String`.
    /// - parameter type: The type to encode to.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter configuration: Configuration values specifying how the CSV output should look like.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    @inlinable public convenience init<S:Sequence,Sub:Sequence>(output type: String.Type, rows: S, configuration: Configuration = .init()) throws where S.Element==Sub, Sub.Element:StringProtocol {
        fatalError()
    }
    
    /// Creates a writer instance that will be used to encode CSV-formatted data into a `Data` blob.
    /// - parameter type: The type to encode to.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter configuration: Configuration values specifying how the CSV output should look like.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    @inlinable public convenience init<S:Sequence,Sub:Sequence>(output type: Data.Type, rows: S, configuration: Configuration = .init()) throws where S.Element==Sub, Sub.Element:StringProtocol {
        fatalError()
    }
    
    /// Creates a writer instance that will be used to encode CSV-formatted data into a file pointed by the given URL.
    /// - parameter fileURL: The URL pointing to the targeted file.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter replacing: In case an existing file is under the given URL, this Boolean indicates that the file will be overwritten (`true`), or the information will be append to it (`false`).
    /// - parameter configuration: Configuration values specifying how the CSV output should look like.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    @inlinable public convenience init<S:Sequence,Sub:Sequence>(output fileURL: URL, rows: S, replacing: Bool, configuration: Configuration = .init()) throws where S.Element==Sub, Sub.Element:StringProtocol {
        fatalError()
    }
}

extension CSVWriter {
    /// Creates a writer instance that will be used to encode CSV-formatted data into a `String`.
    /// - parameter type: The type to encode to.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter setter: Closure receiving the default configuration values and gives you the possibility to change them.
    /// - parameter configuration: Default configuration values for the `CSVWriter`.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    @inlinable public convenience init<S:Sequence,Sub:Sequence>(output type: String.Type, rows: S, setter: (_ configuration: inout Configuration) -> Void) throws where S.Element==Sub, Sub.Element:StringProtocol {
        var configuration = Configuration()
        setter(&configuration)
        try self.init(output: type, rows: rows, configuration: configuration)
    }
    
    /// Creates a writer instance that will be used to encode CSV-formatted data into a `Data` blob.
    /// - parameter type: The type to encode to.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter setter: Closure receiving the default configuration values and gives you the possibility to change them.
    /// - parameter configuration: Default configuration values for the `CSVWriter`.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    @inlinable public convenience init<S:Sequence,Sub:Sequence>(output type: Data.Type, rows: S, setter: (_ configuration: inout Configuration) -> Void) throws where S.Element==Sub, Sub.Element:StringProtocol {
        var configuration = Configuration()
        setter(&configuration)
        try self.init(output: type, rows: rows, configuration: configuration)
    }
    
    /// Creates a writer instance that will be used to encode CSV-formatted data into a file pointed by the given URL.
    /// - parameter fileURL: The URL pointing to the targeted file.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter replacing: In case an existing file is under the given URL, this Boolean indicates that the file will be overwritten (`true`), or the information will be append to it (`false`).
    /// - parameter setter: Closure receiving the default configuration values and gives you the possibility to change them.
    /// - parameter configuration: Default configuration values for the `CSVWriter`.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    @inlinable public convenience init<S:Sequence,Sub:Sequence>(output fileURL: URL, rows: S, replacing: Bool, setter: (_ configuration: inout Configuration) -> Void) throws where S.Element==Sub, Sub.Element:StringProtocol {
        var configuration = Configuration()
        setter(&configuration)
        try self.init(output: fileURL, rows: rows, replacing: replacing, configuration: configuration)
    }
}

// MARK: -

extension CSVWriter {
    /// Returns a `String` with the CSV-encoded representation of the `rows` supplied.
    /// - parameter type: The type to encode to.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter configuration: Configuration values specifying how the CSV output should look like.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    /// - returns: Swift `String` containing the formatted CSV data.
    @inlinable public static func serialize<S:Sequence,Sub:Sequence>(to type: String.Type, rows: S, configuration: Configuration = .init()) throws -> String where S.Element==Sub, Sub.Element:StringProtocol {
        let writer = try CSVWriter(output: type, rows: rows, configuration: configuration)
        fatalError()
    }
    
    /// Returns a CSV-encoded representation of the `rows` supplied.
    /// - parameter type: The type to encode to.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter configuration: Configuration values specifying how the CSV output should look like.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    /// - returns: Data blob in a CSV format.
    @inlinable public static func serialize<S:Sequence,Sub:Sequence>(to type: Data.Type, rows: S, configuration: Configuration = .init()) throws -> Data where S.Element==Sub, Sub.Element:StringProtocol {
        let writer = try CSVWriter(output: type, rows: rows, configuration: configuration)
        fatalError()
    }
    
    /// Creates a file with the CSV-encoded representation of the `rows` supplied.
    /// - parameter fileURL: The URL pointing to the targeted file.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter replacing: In case an existing file is under the given URL, this Boolean indicates that the file will be overwritten (`true`), or the information will be append to it (`false`).
    /// - parameter configuration: Configuration values specifying how the CSV output should look like.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    @inlinable public static func serialize<S:Sequence,Sub:Sequence>(to fileURL: URL, rows: S, replacing: Bool, configuration: Configuration = .init()) throws where S.Element==Sub, Sub.Element:StringProtocol {
        let writer = try CSVWriter(output: fileURL, rows: rows, replacing: replacing, configuration: configuration)
        fatalError()
    }
}

extension CSVWriter {
    /// Returns a `String` with the CSV-encoded representation of the `rows` supplied.
    /// - parameter type: The type to encode to.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter setter: Closure receiving the default configuration values and gives you the possibility to change them.
    /// - parameter configuration: Default configuration values for the `CSVWriter`.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    /// - returns: Swift `String` containing the formatted CSV data.
    @inlinable public static func serialize<S:Sequence,Sub:Sequence>(to type: String.Type, rows: S, setter: (_ configuration: inout Configuration) -> Void) throws -> String where S.Element==Sub, Sub.Element:StringProtocol {
        var configuration = Configuration()
        setter(&configuration)
        return try CSVWriter.serialize(to: type, rows: rows, configuration: configuration)
    }
    
    /// Returns a CSV-encoded representation of the `rows` supplied.
    /// - parameter type: The type to encode to.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter setter: Closure receiving the default configuration values and gives you the possibility to change them.
    /// - parameter configuration: Default configuration values for the `CSVWriter`.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    /// - returns: Data blob in a CSV format.
    @inlinable public static func serialize<S:Sequence,Sub:Sequence>(to type: Data.Type, rows: S, setter: (_ configuration: inout Configuration) -> Void) throws -> Data where S.Element==Sub, Sub.Element:StringProtocol {
        var configuration = Configuration()
        setter(&configuration)
        return try CSVWriter.serialize(to: type, rows: rows, configuration: configuration)
    }
    
    /// Creates a file with the CSV-encoded representation of the `rows` supplied.
    /// - parameter fileURL: The URL pointing to the targeted file.
    /// - parameter rows: A sequence of rows whose elements are sequences of `String`-like elements.
    /// - parameter replacing: In case an existing file is under the given URL, this Boolean indicates that the file will be overwritten (`true`), or the information will be append to it (`false`).
    /// - parameter setter: Closure receiving the default configuration values and gives you the possibility to change them.
    /// - parameter configuration: Default configuration values for the `CSVWriter`.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    @inlinable public static func serialize<S:Sequence,Sub:Sequence>(to fileURL: URL, row: S, replacing: Bool, setter: (_ configuration: inout Configuration) -> Void) throws where S.Element==Sub, Sub.Element:StringProtocol {
        var configuration = Configuration()
        setter(&configuration)
        try CSVWriter.serialize(to: fileURL, rows: row, replacing: replacing, configuration: configuration)
    }
}

// MARK: -

//extension CSVWriter {
//    public static func data<S:Sequence,Sub:Sequence>(rows: S, encoding: String.Encoding = .utf8, configuration: Configuration = .init()) throws -> Data where S.Element == Sub, Sub.Element == String {
//        guard let encoder = encoding.scalarEncoder else {
//            throw Error.unsupportedEncoding(encoding)
//        }
//
//        let stream = OutputStream(toMemory: ())
//        let writer = try CSVWriter(output: (stream, true), configuration: configuration, encoder: encoder)
//        try writer.beginFile(bom: encoding.bom, writeHeaders: true)
//
//        for row in rows {
//            try writer.write(row: row)
//        }
//        try writer.endFile()
//
//        guard let result = writer.dataInMemory else {
//            throw Error.outputStreamFailed("The data containing the CSV file couldn't be retrieved from memory.", underlyingError: stream.streamError)
//        }
//        return result
//    }
//}

//extension CSVWriter {
//    /// Initializes a `CSVWriter` pointing to a file in memory, a network socket, or a buffer in memory.
//    ///
//    /// Please notice, that an `OutputStream` is created internally and it is opened right away. Therefore, only create the `CSVWriter` when you are about to write on the stream.
//    /// - parameter url: If not `nil`, it indicates the location of a file in memory or a network socket. If `nil`, a buffer in memory will be allocated. If a file already exists, the file will be removed and a brand new one will be created.
//    /// - parameter encoding: The `String` encoding being used (UTF8 by default).
//    /// - parameter configuration: Configuration specifying how the CSV output should look like.
//    /// - throws: `CSVWriter.Error` exclusively.
//    public convenience init(url: URL?, encoding: String.Encoding = .utf8, configuration: Configuration = .init()) throws {
//        guard let encoder = encoding.scalarEncoder else {
//            throw Error.unsupportedEncoding(encoding)
//        }
//
//        let stream: OutputStream
//        if let url = url {
//            guard let s = OutputStream(url: url, append: false) else {
//                throw Error.outputStreamFailed("The output stream couldn't be initialized on url \(url)", underlyingError: nil)
//            }
//            stream = s
//        } else {
//            stream = OutputStream(toMemory: ())
//        }
//
//        try self.init(output: (stream, true), configuration: configuration, encoder: encoder)
//        try self.beginFile(bom: encoding.bom, writeHeaders: true)
//    }
//
//    /// Initializes a `CSVWriter` poiting to file or network socket.
//    ///
//    /// Any field or row added manually will be appended to the pointed file/socket. Also, no headers will be writen to the pointed file/socket.
//    /// - remark: Be sure to *end* the writer before trying to access the writen data.
//    /// - parameter url: The file or network socket location.
//    /// - parameter encoding: The `String` encoding being used (UTF8 by default).
//    /// - parameter configuration: Configuration specifying how the CSV output should look like.
//    /// - throws: `CSVWriter.Error` exclusively.
//    public convenience init(appendingToURL url: URL, encoding: String.Encoding = .utf8, configuration: Configuration = .init()) throws {
//        guard let encoder = encoding.scalarEncoder else {
//            throw Error.unsupportedEncoding(encoding)
//        }
//
//        guard let stream = OutputStream(url: url, append: true) else {
//            throw Error.outputStreamFailed("The output stream couldn't be initialized on url \(url)", underlyingError: nil)
//        }
//
//        try self.init(output: (stream, true), configuration: configuration, encoder: encoder)
//        try self.beginFile(bom: nil, writeHeaders: false)
//    }
//}
