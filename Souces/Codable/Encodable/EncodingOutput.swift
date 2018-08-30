import Foundation

extension ShadowEncoder {
    ///
    internal class Output {
        ///
        private init() {}
        
        ///
        internal static func make(_ output: Output.Request) throws -> Output {
            switch output {
            case .data(let capacity):
                return DataBlob(capacity: capacity)
            case .file(let url):
                return try File(url: url)
            }
        }
    }
}

extension ShadowEncoder.Output {
    ///
    internal enum Request {
        case data(capacity: Int)
        case file(url: URL)
    }
}

extension ShadowEncoder.Output {
    ///
    internal class DataBlob: ShadowEncoder.Output {
        ///
        private(set) var data: Data
        
        ///
        fileprivate init(capacity: Int) {
            self.data = Data(capacity: capacity)
            super.init()
        }
    }
}

extension ShadowEncoder.Output {
    ///
    internal class File: ShadowEncoder.Output {
        ///
        //var file: FileHandle
        
        ///
        /// - throws: `EncodingError` exclusively.
        fileprivate init(url: URL) throws {
//            guard url.isFileURL else {
//
//            }
//            // Wrap over File management errors
        }
        
        ///
        func close() throws {
            
        }
    }
}
