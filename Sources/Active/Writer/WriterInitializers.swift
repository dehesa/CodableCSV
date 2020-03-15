import Foundation

extension CSVWriter {
    /// Generates a data blob containing the data given in `rows` formatted as a CSV file.
    /// - parameter rows: A sequence of rows. Each row is a sequence of `String`s.
    /// - parameter encoding: The `String` encoding being used (UTF8 by default).
    /// - parameter configuration: Configuration specifying how the CSV output should look like.
    /// - throws: `CSVWriter.Error` exclusively.
    /// - returns: Data blob in a CSV format.
    public static func data<S:Sequence,Sub:Sequence>(rows: S, encoding: String.Encoding = .utf8, configuration: Configuration = .init()) throws -> Data where S.Element == Sub, Sub.Element == String {
        #warning("Implement me")
        fatalError()
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
    }
}

extension CSVWriter {
    /// Initializes a `CSVWriter` pointing to a file in memory, a network socket, or a buffer in memory.
    ///
    /// Please notice, that an `OutputStream` is created internally and it is opened right away. Therefore, only create the `CSVWriter` when you are about to write on the stream.
    /// - parameter url: If not `nil`, it indicates the location of a file in memory or a network socket. If `nil`, a buffer in memory will be allocated. If a file already exists, the file will be removed and a brand new one will be created.
    /// - parameter encoding: The `String` encoding being used (UTF8 by default).
    /// - parameter configuration: Configuration specifying how the CSV output should look like.
    /// - throws: `CSVWriter.Error` exclusively.
    public convenience init(url: URL?, encoding: String.Encoding = .utf8, configuration: Configuration = .init()) throws {
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
        #warning("Implement me")
        fatalError()
    }
    
    /// Initializes a `CSVWriter` poiting to file or network socket.
    ///
    /// Any field or row added manually will be appended to the pointed file/socket. Also, no headers will be writen to the pointed file/socket.
    /// - remark: Be sure to *end* the writer before trying to access the writen data.
    /// - parameter url: The file or network socket location.
    /// - parameter encoding: The `String` encoding being used (UTF8 by default).
    /// - parameter configuration: Configuration specifying how the CSV output should look like.
    /// - throws: `CSVWriter.Error` exclusively.
    public convenience init(appendingToURL url: URL, encoding: String.Encoding = .utf8, configuration: Configuration = .init()) throws {
        guard let encoder = encoding.scalarEncoder else {
            throw Error.unsupportedEncoding(encoding)
        }
        
        guard let stream = OutputStream(url: url, append: true) else {
            throw Error.outputStreamFailed("The output stream couldn't be initialized on url \(url)", underlyingError: nil)
        }
        
        try self.init(output: (stream, true), configuration: configuration, encoder: encoder)
        try self.beginFile(bom: nil, writeHeaders: false)
    }
}
