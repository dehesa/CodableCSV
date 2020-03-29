extension ShadowEncoder.Sink {
    /// The encoder buffer caching the half-encoded CSV rows.
    internal final class Buffer {
        /// The buffering strategy.
        let strategy: Strategy.EncodingBuffer
        /// The underlying storage.
        private var storage: [Int: [Int:String]]
        
        /// Designated initializer.
        init(strategy: Strategy.EncodingBuffer) {
            self.strategy = strategy
            
            let capacity: Int
            switch strategy {
            case .keepAll:     capacity = 32
            case .unfulfilled: capacity = 8
            case .sequential:  capacity = 1
            }
            self.storage = .init(minimumCapacity: capacity)
        }
    }
}

extension ShadowEncoder.Sink.Buffer {
    /// The
    var isEmpty: Bool {
        self.storage.isEmpty
    }
    
    /// The number of rows being hold by the receiving buffer.
    var count: Int {
        self.storage.count
    }
    
    /// Returns the number of fields that have been received for the given row.
    ///
    /// If none, it returns *zero*.
    func fieldCount(for rowIndex: Int) -> Int {
        self.storage[rowIndex]?.count ?? 0
    }
    
    /// Stores the provided `value` into the temporary storage associating its position as `rowIndex` and `fieldIndex`.
    ///
    /// If there was a value at that position, the value is overwritten.
    func store(value: String, at rowIndex: Int, _ fieldIndex: Int) {
        var row = self.storage[rowIndex] ?? .init()
        row[fieldIndex] = value
        self.storage[rowIndex] = row
    }
    
    /// Retrieves and removes from the buffer the indicated value.
    func retrieveField(at rowIndex: Int, _ fieldIndex: Int) -> String? {
        self.storage[rowIndex]?.removeValue(forKey: fieldIndex)
    }
    
    /// Retrieves and removes from the buffer all rows/fields.
    func retrieveAll() -> RowSequence {
        let sequence = RowSequence(self.storage)
        self.storage.removeAll(keepingCapacity: false)
        return sequence
    }
}

extension ShadowEncoder.Sink.Buffer {
    ///
    struct RowSequence: Sequence, IteratorProtocol {
        ///
        private var inverseSort: [(key: Int, value: [Int:String])]
        ///
        init(_ storage: [Int:[Int:String]]) {
            self.inverseSort = storage.sorted { $0.key > $1.key }
        }
        ///
        mutating func next() -> Row? {
            guard !self.inverseSort.isEmpty else { return nil }
            let element = self.inverseSort.removeLast()
            var fields = element.value.map { Field(index: $0.key, value: $0.value) }
            fields.sort { $0.index < $1.index }
            return Row(index: element.key, fields: fields)
        }
        ///
        var firstIndex: (row: Int, field: Int)? {
            guard let row = self.inverseSort.last else { return nil }
            guard let fieldIndex = row.value.keys.sorted().first else { fatalError() }
            return (row.key, fieldIndex)
        }
    }
}

extension ShadowEncoder.Sink.Buffer {
    ///
    struct Row {
        ///
        let index: Int
        ///
        let fields: [Field]
    }
    
    struct Field {
        ///
        let index: Int
        ///
        let value: String
    }
}
