import Foundation

extension ShadowEncoder {
    /// Class wrapping the output of the encoding process.
    internal class Output {
        /// The `String` encoding used in the output.
        let encoding: String.Encoding
        /// The output stream where the encoded values are writen to.
        let stream: OutputStream
        /// The instance writing the CSV data.
        private let writer: CSVWriter
        
        /// Designated initializer for this class.
        /// - parameter encoding: The `String` encoding used on the output.
        /// - parameter stream: The output stream where the encoded values are writen to.
        /// - throws: `EncodingError` exclusively.
        init(encoding: String.Encoding, stream: OutputStream, configuration: EncoderConfiguration) throws {
            self.encoding = encoding
            
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
            
            self.stream = stream
            
            try self.writer.beginFile()
        }
        
        /// The encoding configuration.
        var configuration: EncoderConfiguration {
            return self.writer.configuration
        }
        
        /// The total number of records that have been fully encoded so far.
        ///
        /// This number doesn't take the header row in consideration.
        var recordsCount: Int {
            var offset = 0
            if let maxFields = self.writer.expectedFieldsPerRow, self.writer.indices.field >= maxFields {
                offset = 1
            }
            return self.writer.indices.row + offset
        }
        
        /// The total number of fields within the current record (so far).
        var fieldsCount: Int {
            return self.writer.indices.field
        }
        
        /// The number of fields that each record must have.
        ///
        /// If `nil` that number hasn't been inferred yet.
        var maxFieldsPerRecord: Int? {
            return self.writer.expectedFieldsPerRow
        }
        
        ///
        func startNextRecord() throws -> Int {
            #warning("TODO")
            fatalError()
        }
        
        ///
        func startRecord(at index: Int) throws {
            #warning("TODO")
            fatalError()
        }
        
        ///
        func encodeNext(field: String) throws {
            #warning("TODO")
            fatalError()
        }
        
        ///
        func encode(field: String, at index: Int) throws {
            #warning("TODO")
            fatalError()
        }
        
        ///
        func encodeNext(record: [String]) throws {
            #warning("TODO")
            fatalError()
        }
    }
}
