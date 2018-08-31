import Foundation

extension ShadowEncoder {
    /// Sink for all CSV rows.
    internal final class Sink {
        /// The instance writing the CSV data.
        private let writer: CSVWriter
        /// The encoding configuration.
        var configuration: CSV.Configuration { return self.writer.configuration }
        
        /// - throws: `EncodingError` exclusively.
        init(stream: OutputStream, encoding: String.Encoding, configuration: CSV.Configuration) throws {
            guard let encoder = encoding.scalarEncoder else {
                let context = EncodingError.Context(codingPath: [], debugDescription: "The given encoding \"\(encoding)\" is not yet supported.")
                throw EncodingError.invalidValue(Any?.self, context)
            }
            
            do {
                self.writer = try CSVWriter(output: (stream, true), configuration: configuration, encoder: encoder)
            } catch let error {
                let context = EncodingError.Context(codingPath: [], debugDescription: "CSVWriter couldn't be initialized.", underlyingError: error)
                throw EncodingError.invalidValue(Any?.self, context)
            }
        }
    }
}
