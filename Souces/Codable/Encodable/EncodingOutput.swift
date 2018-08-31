import Foundation

extension ShadowEncoder {
    /// Class wrapping the output of the encoding process.
    internal class Output {
        /// The `String` encoding used in the output.
        let encoding: String.Encoding
        /// The output stream where the encoded values are writen to.
        let stream: OutputStream
        
        /// Designated initializer for this class.
        /// - parameter encoding: The `String` encoding used on the output.
        /// - parameter stream: The output stream where the encoded values are writen to.
        private init(encoding: String.Encoding, stream: OutputStream) {
            self.encoding = encoding
            self.stream = stream
        }
        
        /// Creates the appropriate subclass depending on the required output target.
        /// - parameter output: The user desired output.
        /// - returns: The `Ouput` wrapper.
        internal static func make(_ output: Output.Request) throws -> Output {
            switch output {
            case .data(let encoding):
                return DataBlob(encoding: encoding)
            case .file(let url, let replacingData, let encoding):
                return try File(url: url, replacingData: replacingData, encoding: encoding)
            }
        }
        
        /// All the types of output the `ShadowEncoder` offers.
        internal enum Request {
            /// The `ShadowEncoder` will return the encoding value as a data blob with the given encoding.
            case data(encoding: String.Encoding)
            /// The `ShadowEncoder` will return the encoding value as file in the File System.
            case file(url: URL, replacingData: Bool, encoding: String.Encoding?)
        }
    }
}

extension ShadowEncoder.Output {
    /// Subclass where the output can be queried as a data blob.
    internal class DataBlob: ShadowEncoder.Output {
        /// Designated initializer for the data output.
        ///
        /// It generates an `OutputStream` pointing to memory.
        fileprivate init(encoding: String.Encoding) {
            super.init(encoding: encoding, stream: OutputStream(toMemory: ()))
        }
        
        /// Generates a `Data` container for the "so far" encoded values.
        func data() throws -> Data {
            guard var result = stream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
                let context = EncodingError.Context(codingPath: [], debugDescription: "The memory containing the information couldn't be packed as a Data blob.")
                throw EncodingError.invalidValue(Any?.self, context)
            }
            result.insertBOM(encoding: encoding)
            return result
        }
    }
}

extension ShadowEncoder.Output {
    /// Output subclass where the output can be queried as a file in the host File System.
    internal class File: ShadowEncoder.Output {
        ///
        //var file: FileHandle
        
        ///
        /// - throws: `EncodingError` exclusively.
        fileprivate init(url: URL, replacingData: Bool, encoding: String.Encoding?) throws {
            guard url.isFileURL else {
                let context = EncodingError.Context(codingPath: [], debugDescription: "The URL \"\(url)\" is not a file.")
                throw EncodingError.invalidValue(Any?.self, context)
            }
            
            guard let stream = OutputStream(toFileAtPath: url.absoluteString, append: !replacingData) else {
                let context = EncodingError.Context(codingPath: [], debugDescription: "The file URL \"\(url)\" couldn't be opened to write on it.")
                throw EncodingError.invalidValue(Any?.self, context)
            }
            
            #warning("TODO: Figure out previous file encoding.")
            super.init(encoding: encoding ?? .utf8, stream: stream)
        }
        
        ///
        func close() throws {
            
        }
    }
}
