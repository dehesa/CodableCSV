import Foundation

/// A container that can be included into a codingChain.
internal protocol CodingContainer: class {
    /// The coding key representing the receiving container.
    var codingKey: CSV.Key { get }
}

/// The steps on the coding chain that has been taken.
internal protocol CodingState {
    /// Initializes and verifies that the given container are in correct state.
    ///
    /// Correct state addresses the need for the decoding containers to be in their correct orders (e.g. file, record, field) and that there is only one file and record decoding containers.
    init(containers: [CodingContainer]) throws
}

/// A downwards chain of decoding containers.
///
/// Usually starting with a file container followed by a record container.
internal struct CodingChain<State:CodingState> {
    /// All the containers, lined up on calling order.
    let containers: [CodingContainer]
    /// Returns the state of the receiving container chain.
    let state: State
    
    /// Designated initializer giving the exact container chain.
    /// - parameter containers: The container chain to hold in this instance.
    init(containers: [CodingContainer]) throws {
        self.state = try State.init(containers: containers)
        self.containers = containers
    }
    
    /// Adds the given containers at the end of the stored container chain.
    /// - parameter containers: The decoding containers to add to the chain.
    /// - returns: A new decoding chain with the requested changes.
    func adding(containers: CodingContainer...) throws -> CodingChain {
        return try CodingChain(containers: self.containers + containers)
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
        return try! CodingChain(containers: containers)
    }
    
    /// Full coding path till the last container.
    var codingPath: [CodingKey] {
        return self.containers.map { $0.codingKey }
    }
}
