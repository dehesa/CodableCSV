internal extension CSVReader {
    /// Buffer used to stored previously read unicode scalars.
    ///
    /// This buffer is a reference value so it can be pointed to by several _users_.
    final class ScalarBuffer: IteratorProtocol {
        /// Unicode scalars read inferring configuration variables that were unknown.
        ///
        /// This buffer is reversed to make it efficient to iterate/remove elements. This means, as elements arrive they are placed at the beginning of the array.
        private var _readScalars: [Unicode.Scalar]
        
        /// Creates the buffer with a given capacity value.
        init(reservingCapacity capacity: Int) {
            self._readScalars = []
            self._readScalars.reserveCapacity(capacity)
        }
        
        func next() -> Unicode.Scalar? {
            guard !self._readScalars.isEmpty else { return nil }
            return self._readScalars.removeLast()
        }
        
        /// Inserts a single unicode scalar at the beginning of the buffer.
        func preppend(scalar: Unicode.Scalar) {
            self._readScalars.append(scalar)
        }
        
        /// Inserts a sequence of scalars at the beginning of the buffer.
        func preppend<S:Sequence>(scalars: S) where S.Element == Unicode.Scalar {
            self._readScalars.append(contentsOf: scalars.reversed())
        }
        
        /// Appends a single unicode scalar to the buffer.
        func append(scalar: Unicode.Scalar) {
            self._readScalars.insert(scalar, at: 0)
        }
        
        /// Appends a sequence of unicode scalars to the buffer.
        func append<S:Sequence>(scalars: S) where S.Element == Unicode.Scalar {
            self._readScalars.insert(contentsOf: scalars.reversed(), at: 0)
        }
        
        /// Removes all scalars in the buffer.
        func removeAll() {
            self._readScalars.removeAll()
        }
    }
}
