infix operator ?!

extension Optional {
    /// Checks whether the value exists. If so, it returns the value; if not, it throws the given error.
    /// - parameter lhs: Optional value to check for existance.
    /// - parameter rhs: Swift error to throw in case of no value.
    /// - returns: The value (non-optional) passed as parameter.
    /// - throws: The Swift error returned on the right hand-side autoclosure.
    internal static func ?!(lhs: Self, rhs: @autoclosure ()->Swift.Error) throws -> Wrapped {
        switch lhs {
        case .some(let v): return v
        case .none: throw rhs()
        }
    }
}
