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
    /// The number of rows being hold by the receiving buffer.
    var count: Int {
        #warning("TODO")
        fatalError()
    }
    
    /// Returns the number of fields that have been received for the given row.
    ///
    /// If none, it returns *zero*.
    func fieldCount(forRowIndex rowIndex: Int) -> Int {
        #warning("TODO")
        fatalError()
    }
    
    ///
    func store(value: String, at rowIndex: Int, _ fieldIndex: Int) {
        #warning("TODO")
        fatalError()
    }
}
