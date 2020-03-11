/// Buffer used to stored previously read unicode scalars.
internal final class ScalarBuffer: IteratorProtocol {
    /// Unicode scalars read inferring configuration variables that were unknown.
    ///
    /// This buffer is reversed to make it efficient to remove elements.
    private var readScalars: [Unicode.Scalar]
    
    /// Creates the buffer with a given capacity value.
    init(reservingCapacity capacity: Int = 10) {
        self.readScalars = []
        self.readScalars.reserveCapacity(capacity)
    }
    
    func next() -> Unicode.Scalar? {
        guard !self.readScalars.isEmpty else { return nil }
        return self.readScalars.removeLast()
    }
    
    /// Inserts a single unicode scalar at the beginning of the buffer.
    func preppend(scalar: Unicode.Scalar) {
        self.readScalars.append(scalar)
    }
    
    /// Inserts a sequence of scalars at the beginning of the buffer.
    func preppend<S:Sequence>(scalars: S) where S.Element == Unicode.Scalar {
        self.readScalars.append(contentsOf: scalars.reversed())
    }
    
    /// Appends a single unicode scalar to the buffer.
    func append(scalar: Unicode.Scalar) {
        self.readScalars.insert(scalar, at: self.readScalars.startIndex)
    }
    
    /// Appends a sequence of unicode scalars to the buffer.
    func append<S:Sequence>(scalars: S) where S.Element == Unicode.Scalar {
        self.readScalars.insert(contentsOf: scalars.reversed(), at: self.readScalars.startIndex)
    }
    
    /// Removes all scalars in the buffer.
    func removeAll() {
        self.readScalars.removeAll()
    }
}
