import Foundation

/// A downwards chain of decoding containers.
///
/// Usually starting with a file container followed by a record container.
internal struct CodingChain {
    /// All the containers, lined up on calling order.
    let containers: [CodingContainer]
    /// Returns the state of the receiving container chain.
    let state: State
    
    /// Creates an empty coding chain.
    init() {
        self.state = .overview
        self.containers = []
    }
    
    /// Initializer giving in its argument the exact container chain.
    /// - parameter containers: The container chain to hold in this instance.
    /// - returns: An initialized instance if the coding chain has valid state. `nil` otherwise.
    init?(containers: [CodingContainer]) {
        guard let state = State(containers: containers) else { return nil }
        self.state = state
        self.containers = containers
    }
    
    /// Adds the given containers at the end of the stored container chain.
    /// - parameter containers: The decoding containers to add to the chain.
    /// - returns: A new decoding chain with the requested changes if the coding chain has a valid state. `nil` otherwise.
    func adding(containers: CodingContainer...) -> CodingChain? {
        return CodingChain(containers: self.containers + containers)
    }
    
    /// Removes a given number of containers starting counting from the end of the container chain.
    /// - parameter numContainers: The number of decoding container to delete.
    /// - returns: A new decoding chain with the requested changes.
    func reducing(by numContainers: Int) -> CodingChain {
        let toRemove = (numContainers < self.containers.count)
                       ? numContainers : self.containers.count
        guard toRemove > 0 else { return self }
        
        var containers = self.containers
        containers.removeLast(toRemove)
        return CodingChain(containers: containers)!
    }
    
    /// Full coding path till the last container.
    var codingPath: [CodingKey] {
        return self.containers.map { $0.codingKey }
    }
}

extension CodingChain {
    /// The steps on the decoding chain that has been taken.
    internal enum State {
        /// Nothing have been yet selected.
        case overview
        /// A collection of rows.
        case file(FileContainer)
        /// A record. In other words: a collection of fields/values.
        case record(RecordContainer)
        /// A single field/value.
        case field(FieldContainer)
        
        /// Initializes and verifies that the given container are in correct state.
        ///
        /// Correct state addresses the need for the decoding containers to be in their correct orders (e.g. file, record, field) and that there is only one file and record decoding containers.
        /// - returns: If the chain is valid, the state position/state is returned. Otherwise `nil`.
        fileprivate init?(containers: [CodingContainer]) {
            var state: State = .overview
            
            for container in containers {
                switch container {
                case let file as FileContainer:
                    guard case .overview = state else { return nil }
                    state = .file(file)
                case let record as RecordContainer:
                    guard case .file(_) = state else { return nil }
                    state = .record(record)
                case let field as FieldContainer:
                    switch state {
                    case .record(_): state = .field(field)
                    case .field(_):  break
                    default:         return nil
                    }
                case is WrapperContainer:
                    switch state {
                    case .overview:  guard container is WrapperFileContainer else { return nil }
                    case .file(_):   guard container is WrapperRecordContainer else { return nil }
                    case .record(_): guard container is WrapperFieldContainer else { return nil }
                    case .field(_):  guard container is WrapperFieldContainer else { return nil }
                    }
                default:
                    return nil
                }
            }
            
            self = state
        }
    }
}
