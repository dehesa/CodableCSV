import Foundation
@testable import CSV

extension CSV.Delimiter {
    internal typealias StringPair = (field: String, row: String)
}

extension StringRepresentable {
    /// Force unwrap the careful `StringRepresentable` functions.
    internal var toString: String {
        guard let representation = try! self.string(throwing: { (message) in fatalError(message) }) else {
            fatalError("The receiving instance is unknow.")
        }
        return representation
    }
}
