import Foundation

/// A container that can be included into a codingChain.
internal protocol CodingContainer: class {
    /// The coding key representing the receiving container.
    var codingKey: CSVKey { get }
    
    /// The path of coding keys taken to get to this point in decoding.
    ///
    /// This path doesn't include the receiving container.
    var codingPath: [CodingKey] { get }
    
    /// The coder container the receiving container as its last coding chain link.
    var coder: Coder { get }
}

extension CodingContainer {
    var codingPath: [CodingKey] {
        var result = self.coder.codingPath
        if !result.isEmpty {
            result.removeLast()
        }
        return result
    }
}

/// A container holding an overview of the whole CSV file.
internal protocol FileContainer: CodingContainer {}

/// A container holding a CSV record/row.
internal protocol RecordContainer: CodingContainer {
    /// The row index within the CSV file.
    var recordIndex: Int { get }
}

/// A container holding a single value.
internal protocol FieldContainer: CodingContainer {}

/// A single value container that is wrapping a file or record decoding container.
internal protocol WrapperContainer: CodingContainer {}

/// A single value container that is wrapping a file container.
internal protocol WrapperFileContainer: WrapperContainer {}

/// A single value container that is wrapping a record decoding container.
internal protocol WrapperRecordContainer: WrapperContainer {}

/// A *multiple* value container that is wrapping a CSV field.
internal protocol WrapperFieldContainer: WrapperContainer {}
