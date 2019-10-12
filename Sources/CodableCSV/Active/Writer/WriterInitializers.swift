import Foundation

extension CSVWriter {
    
}

extension CSVWriter {
    /// Generates a data blob containing the data given in `rows` formatted as a CSV file.
    /// - parameter rows: A sequence of rows. Each row is a sequence of `String`s.
    /// - parameter configuration: Generic CSV configuration specifying how the CSV output should look like.
    /// - throws: `CSVWriter.Error` exclusively.
    /// - returns: Data blob in a CSV format.
    public static func data<S:Sequence,Sub:Sequence>(rows: S, encoding: String.Encoding = .utf8, configuration: EncoderConfiguration = .init()) throws -> Data where S.Element == Sub, Sub.Element == String {
        guard let encoder = encoding.scalarEncoder else {
            throw Error.unsupportedEncoding(encoding)
        }
        
        let stream = OutputStream(toMemory: ())
        let writer = try CSVWriter(output: (stream, true), configuration: configuration, encoder: encoder)

        try writer.beginFile()
        for row in rows {
            try writer.write(row: row)
        }
        try writer.endFile()

        guard var result = stream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
            throw Error.outputStreamFailed(message: "The data containing all the CSV file couldn't be retrieved from memory.", underlyingError: stream.streamError)
        }
        result.insertBOM(encoding: encoding)
        return result
    }
}
