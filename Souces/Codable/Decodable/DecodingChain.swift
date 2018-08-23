import Foundation

extension ShadowDecoder {
    /// A downwards chain of decoding containers.
    ///
    /// Usually starting with a file container followed by a record container.
    internal struct DecodingChain {
        /// All the containers, lined up on calling order.
        let containers: [DecodingContainer]
        /// Returns the state of the receiving decoding container chain.
        let state: State
        
        /// Designated initializer giving the exact container chain.
        /// - parameter containers: The container chain to hold in this instance.
        init(containers: [DecodingContainer]) throws {
            self.state = try State(containers: containers)
            self.containers = containers
        }
        
        /// Adds the given containers at the end of the stored container chain.
        /// - parameter containers: The decoding containers to add to the chain.
        /// - returns: A new decoding chain with the requested changes.
        func adding(containers: DecodingContainer...) throws -> DecodingChain {
            return try DecodingChain(containers: self.containers + containers)
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
            return try! DecodingChain(containers: containers)
        }
        
        /// Full coding path till the last container.
        var codingPath: [CodingKey] {
            return self.containers.map { $0.codingKey }
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
        case record(RecordDecodingContainer)
        /// A single field/value.
        case field(ShadowDecoder.Field)
        
        /// Initializes and verifies that the given container are in correct state.
        ///
        /// Correct state addresses the need for the decoding containers to be in their correct orders (e.g. file, record, field) and that there is only one file and record decoding containers.
        init(containers: [DecodingContainer]) throws {
            var state: State = .overview
            let codingPath: [CodingKey] = containers.map { $0.codingKey }
            
            for container in containers {
                switch container {
                case is FileDecodingContainer:
                    guard case .overview = state else {
                        throw DecodingError.invalidContainer(codingPath: codingPath)
                    }
                    state = .file(container as! FileDecodingContainer)
                case is RecordDecodingContainer:
                    guard case .file(_) = state else {
                        throw DecodingError.invalidContainer(codingPath: codingPath)
                    }
                    state = .record(container as! RecordDecodingContainer)
                case is ShadowDecoder.Field:
                    switch state {
                    case .record(_):
                        state = .field(container as! ShadowDecoder.Field)
                    case .field(_):
                        break
                    default:
                        throw DecodingError.invalidContainer(codingPath: codingPath)
                    }
                case is WrapperDecodingContainer:
                    switch state {
                    case .overview:
                        guard container is ShadowDecoder.FileWrapper else {
                            throw DecodingError.invalidContainer(codingPath: codingPath)
                        }
                    case .file(_):
                        guard container is ShadowDecoder.RecordWrapper else {
                            throw DecodingError.invalidContainer(codingPath: codingPath)
                        }
                    case .record(_), .field(_):
                        throw DecodingError.invalidContainer(codingPath: codingPath)
                    }
                default:
                    throw DecodingError.invalidContainer(codingPath: codingPath)
                }
            }
            
            self = state
        }
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
