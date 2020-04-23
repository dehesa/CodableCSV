import Foundation

extension InputStream {
    /// Stream for reading from stdin.
    public static var stdin: InputStream {
        return InputStream(fileAtPath: "/dev/stdin")!
    }
}

internal extension Data {
    /// Initialize Data by reading entire input stream. May throw a stream error.
    /// - parameter stream: Stream to read.
    /// - parameter chunk: Chunk size.
    /// - throws: An NSError object representing the stream error.
    init(stream: InputStream, chunk: Int) throws {
        stream.open()
        defer { stream.close() }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunk)
        defer { buffer.deallocate() }

        self.init()

        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: chunk)

            guard count > 0 else {
                if let error = stream.streamError {
                    throw error
                }
                break
            }

            append(buffer, count: count)
        }
    }
}
