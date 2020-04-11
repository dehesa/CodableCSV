extension ShadowDecoder.Source {
    /// The decoder buffer caching the decoded CSV rows.
    internal final class Buffer {
        /// The buffering strategy.
        let strategy: Strategy.DecodingBuffer
        /// The underlying storage.
        private var _storage: [Int:[String]]
        
        /// Designated initializer.
        init(strategy: Strategy.DecodingBuffer) {
            self.strategy = strategy
            
            let capacity: Int
            switch strategy {
            case .keepAll:     capacity = 128
//            case .unrequested: capacity = 16
            case .sequential:  capacity = 2
            }
            self._storage = .init(minimumCapacity: capacity)
        }
    }
}

extension ShadowDecoder.Source.Buffer {
    /// Stores the given row at the given position.
    func store(_ row: [String], at index: Int) {
        self._storage[index] = row
    }
    
    /// Retrieves the row at the given position.
    func fetch(at index: Int) -> [String]? {
        return self._storage[index]
    }
    
//    /// Retrieves the field, removing it from its place.
//    func retrieve(at rowIndex: Int, field: Int) -> String? {
//        guard let row = self.storage[rowIndex] else { return nil }
//        return nil
//    }
    
    ///
    func removeAll() {
        self._storage.removeAll()
    }
}
