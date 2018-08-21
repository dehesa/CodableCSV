import Foundation

extension ShadowDecoder {
    /// A downwards chain of decoding containers.
    ///
    /// Usually starting with a file container followed by a record container.
    internal struct DecodingChain {
        /// All the containers, lined up on calling order.
        let containers: [DecodingContainer]
        
        /// Designated initializer giving the exact container chain.
        /// - parameter containers: The container chain to hold in this instance.
        init(containers: [DecodingContainer]) {
            self.containers = containers
        }
        
        /// Adds the given containers at the end of the stored container chain.
        /// - parameter containers: The decoding containers to add to the chain.
        /// - returns: A new decoding chain with the requested changes.
        func adding(containers: DecodingContainer...) -> DecodingChain {
            return DecodingChain(containers: self.containers + containers)
        }
        
        /// Removes a given number of containers starting counting from the end of the container chain.
        /// - parameter numContainers: The number of decoding container to delete.
        /// - returns: A new decoding chain with the requested changes.
        func reducing(by numContainers: Int) -> DecodingChain {
            let toRemove = (numContainers < self.containers.count)
                ? numContainers : self.containers.count
            guard toRemove > 0 else { return self }
            
            var containers = self.containers
            containers.removeLast(toRemove)
            return DecodingChain(containers: containers)
        }
        
        /// Full coding path till the last container.
        var codingPath: [CodingKey] {
            return self.containers.map { $0.codingKey }
        }
        
        /// Returns the state of the receiving decoding container chain.
        var state: State {
            guard let file = self.fileContainer else { return .overview }
            guard let record = self.recordContainer else { return .file(file) }
            guard let field = self.fieldContainer else { return .record(record, file: file) }
            return .field(field, file: file, record: record)
        }
        
        /// Finds (if any) the file decoding container within the decoding chain.
        var fileContainer: FileDecodingContainer? {
            return self.containers.findContainer()
        }
        
        /// Finds (if any) the record decoding container within the decoding chain.
        var recordContainer: RecordDecodingContainer? {
            return self.containers.findContainer()
        }
        
        /// Finds (if any) the field decoding container within the decoding chain.
        var fieldContainer: FieldDecodingContainer? {
            return self.containers.findContainer()
        }
    }
}

extension ShadowDecoder.DecodingChain {
    /// The steps on the decoding chain that has been taken.
    internal enum State {
        /// Nothing have been yet selected.
        case overview
        /// A collection of rows.
        case file(FileDecodingContainer)
        /// A record. In other words: a collection of fields/values.
        case record(RecordDecodingContainer, file: FileDecodingContainer)
        /// A single field/value.
        case field(FieldDecodingContainer, file: FileDecodingContainer, record: RecordDecodingContainer)
    }
}

extension Array {
    /// Finds the container of the given type (if any).
    fileprivate func findContainer<T>() -> T? {
        for container in self {
            guard let result = container as? T else { continue }
            return result
        }
        return nil
    }
}
