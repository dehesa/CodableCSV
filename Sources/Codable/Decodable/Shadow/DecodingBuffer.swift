extension ShadowDecoder.Source {
    /// The decoder buffer caching the decoded CSV rows.
    internal final class Buffer {
        /// The buffering strategy.
        let strategy: Strategy.Buffering
        /// The underlying storage.
        private var storage: [Int:[String]]
        /// The first index being stored.
        private var firstIndex: Int
        /// The last index being stored.
        private var lastIndex: Int
        
        /// Designated initializer.
        init(strategy: Strategy.Buffering) {
            self.strategy = strategy
            self.storage = .init(minimumCapacity: 8)
            self.firstIndex = -1
            self.lastIndex = -1
//            #warning("TODO: Buffering strategy")
        }
        
        /// Stores the given row at the given position.
        func store(_ row: [String], at index: Int) {
            precondition(index >= 0)
            self.storage[index] = row
        }
        
        /// Retrieves the row at the given position.
        func retrieve(at index: Int) -> [String]? {
            precondition(index >= 0)
            return self.storage[index]
        }
    }
}
