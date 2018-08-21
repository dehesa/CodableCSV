import Foundation

extension String {
    /// Returns a Boolean indicating whether the receiving string is empty (represents `nil`) or not.
    internal func decodeToNil() -> Bool {
        return self.isEmpty
    }
    
    /// Parses the receiving String looking for specific character chains representing a `true` or `false` value.
    /// - returns: A Boolean if the string could be transformed, or `nil` if the transformation was unsuccessful.
    internal func decodeToBool() -> Bool? {
        switch self.uppercased() {
        case "TRUE", "YES": return true
        case "FALSE", "NO", "": return false
        default: return nil
        }
    }
}
