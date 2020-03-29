extension ShadowEncoder.Sink {
    /// The encoder buffer caching the half-encoded CSV rows.
    internal final class Buffer {
        /// The buffering strategy.
        let strategy: Strategy.EncodingBuffer
        
        /// Designated initializer.
        init(strategy: Strategy.EncodingBuffer) {
            self.strategy = strategy
            #warning("TODO: EncodingBuffer strategy")
        }
    }
}

extension ShadowEncoder.Sink.Buffer {
    ///
    var isEmpty: Bool {
        #warning("TODO")
        fatalError()
    }
    
    /// The number of rows being hold by the receiving buffer.
    var count: Int {
        #warning("TODO")
        fatalError()
    }
    
    /// Returns the number of fields that have been received for the given row.
    ///
    /// If none, it returns *zero*.
    func fieldCount(for rowIndex: Int) -> Int {
        #warning("TODO")
        fatalError()
    }
    
    ///
    func store(value: String, at rowIndex: Int, _ fieldIndex: Int) {
        #warning("TODO")
        fatalError()
    }
    
    /// Retrieves and removes from the buffer the indicated value.
    func retrieveField(at rowIndex: Int, _ fieldIndex: Int) -> String? {
        #warning("TODO")
        fatalError()
    }
    
    /// Retrieves and removes from the buffer all rows/fields from the given indices.
    ///
    /// This function never returns rows at an index smaller than the passed `rowIndex`. Also, for the `rowIndex`, it doesn't return the fields previous the `fieldIndex`.
    func retrieveSequence(from rowIndex: Int, fieldIndex: Int) -> RowSequence {
        #warning("TODO")
        fatalError()
    }
}

extension ShadowEncoder.Sink.Buffer {
    ///
    struct RowSequence: Sequence, IteratorProtocol {
        ///
        mutating func next() -> Row? {
            #warning("TODO")
            fatalError()
        }
        
        var isEmpty: Bool {
            #warning("TODO")
            fatalError()
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
