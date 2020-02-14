import Foundation

/// The coding key used to identify encoding/decoding containers.
public enum CSVKey: CodingKey, CustomDebugStringConvertible {
    // Key indicating a coding container wrapping over a whole CSV file.
    case file
    // Key indicating a coding container wrapping over a CSV row.
    case record(index: Int)
    // Key indicating a coding container wrapping over a CSV field/value.
    case field(index: Int, recordIndex: Int)
    
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
        case .field(let index, _): return "Field \(index)"
        }
    }
    
    public var intValue: Int? {
        switch self {
        case .file: return nil
        case .record(let index): return index
        case .field(let index, _): return index
        }
    }
    
    public var debugDescription: String {
        return self.stringValue
    }
}
