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
            
            try self.writer.beginFile(bom: encoding.bom, writeHeaders: true)
        }
        
        /// The encoding configuration.
        var configuration: EncoderConfiguration {
            return self.writer.configuration
        }
        
        /// The indices to encode next.
        var indices: (row: Int, field: Int) {
            return self.writer.indices
        }
        
        /// The number of records that have been completely encoded so far.
        ///
        /// This number doesn't take the header row in consideration.
        var recordsCount: Int {
            return self.writer.indices.row
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
        
        /// Creates a new record every time this function is called.
        ///
        /// This function will automatically complete the previous record (even when there was no field).
        /// - throws: `CSVWriter.Error` exclusively.
        /// - returns: The index of the created record.
        func startNextRecord() throws -> Int {
//            try self.writer.beginRow()
            return self.writer.indices.row
        }
        
        /// Attaches a field to whatever row is already being worked on.
        ///
        /// This function already checks whether the field is out of row's bounds.
        /// - throws: `CSVWriter.Error` exclusively.
        func encodeNext(field: String) throws {
            try self.writer.write(field: field)
        }
        
        /// Moves the next writing pointer to the record with at `index`.
        /// - throws: `CSVWriter.Error` exclusively.
        func moveToRecord(index: Int) throws {
            //#warning("This can bring a lot of problems like cascading errors in the `Next` type of functions when a function has already been writen.")
            fatalError()
        }
        
        ///
        /// - throws: `CSVWriter.Error` exclusively.
        func moveToField(index: Int) throws {
            //#warning("TODO")
            fatalError()
        }
        
        /// Creates a new row and fills it with the content of the given array.
        ///
        /// The CSV row is not closed when this function finishes. If `encodeNext(field:)` is used, that field is attached to the given record.
        /// - throws: `CSVWriter.Error` if the CSV file has been already closed or
        func encodeNext(record: [String]) throws {
            try self.writer.write(row: record)
        }
    }
}
