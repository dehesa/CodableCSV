import Foundation

extension CSV {
    /// The coding key used to identify encoding/decoding containers.
    public enum Key: CodingKey {
        //
        case file
        //
        case record(index: Int)
        
        public init?(stringValue: String) {
            guard let index = Int(stringValue) else { return nil }
            self = .record(index: index)
        }
        
        public init?(intValue: Int) {
            precondition(intValue > 0)
            self = .record(index: intValue)
        }
        
        public var stringValue: String {
            switch self {
            case .file: return "File"
            case .record(let index): return "Row \(index)"
            }
        }
        
        public var intValue: Int? {
            switch self {
            case .file: return nil
            case .record(let index): return index
            }
        }
    }
}
