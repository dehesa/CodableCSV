import Foundation

internal protocol RollBackable {
    /// Rollbacks the changes if the operation returns `nil`.
    mutating func rollBackOnNil<T>(operation: ()->T?) -> T?
}

extension RecordDecodingContainer {
    func rollBackOnNil<T>(operation: () -> T?) -> T? {
        let fieldIndex = self.currentIndex
        guard let result = operation() else {
            self.currentIndex = fieldIndex
            return nil
        }
        return result
    }
}

extension FileDecodingContainer {
    func rollBackOnNil<T>(operation: () -> T?) -> T? {
        let startIndex = self.currentIndex
        guard let result = operation() else {
            guard startIndex == self.currentIndex else {
//                #warning("TODO: Implement rollbacks on File level decoding containers.")
                return nil
            }
            return nil
        }
        return result
    }
}
