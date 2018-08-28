import Foundation

extension CSVWriter {
    
}

extension CSVWriter {
    /// Generates a data blob containing the data given in `rows` formatted as a CSV file.
    /// - parameter rows: A sequence of rows. Each row is a sequence of `String`s.
    /// - parameter configuration: Generic CSV configuration specifying how the CSV output should look like.
    /// - returns: Data blob in a CSV format.
    public static func data<S:Sequence,Sub:Sequence>(rows: S, configuration: CSV.Configuration = .init()) throws -> Data where S.Element == Sub, Sub.Element == String {
        let stream = OutputStream(toMemory: ())
        let writer = try CSVWriter(stream: stream, configuration: configuration, closeStreamAtEnd: true)

        try writer.beginFile()
        for row in rows {
            try writer.write(row: row)
        }
        try writer.endFile()

        guard let result = stream.property(forKey: .dataWrittenToMemoryStreamKey) as? NSData else {
            throw Error.outputStreamFailed(message: "The data containing all the CSV file couldn't be retrieved from memory.")
        }
        return Data(referencing: result)
    }
}
