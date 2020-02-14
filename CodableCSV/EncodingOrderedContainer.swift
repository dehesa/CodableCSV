import Foundation

internal protocol EncodingOrderedContainer: EncodingValueContainer, UnkeyedEncodingContainer {
    /// Encodes the given array as a row updating the indices in the process.
    ///
    /// This function will throw error in the following cases:
    /// - The encoder encountered invalid data while encoding the subcontainer.
    /// - The subcontainer has more fields than are allowed.
    /// - throws: `EncodingError` exclusively.
    func encodeNext(record: [String], from sequence: Any) throws
}

extension EncodingOrderedContainer {
    public func encodeConditional<T>(_ object: T) throws where T: AnyObject & Encodable {
        //#warning("TODO: Conditional encoding is currently unsupported.")
        return try self.encode(object)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == Bool {
        let result = sequence.map { $0.asString }
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == Int {
        let result = sequence.map { String($0) }
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == Int8 {
        let result = sequence.map { String($0) }
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == Int16 {
        let result = sequence.map { String($0) }
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == Int32 {
        let result = sequence.map { String($0) }
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == Int64 {
        let result = sequence.map { String($0) }
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == UInt {
        let result = sequence.map { String($0) }
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == UInt8 {
        let result = sequence.map { String($0) }
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == UInt16 {
        let result = sequence.map { String($0) }
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == UInt32 {
        let result = sequence.map { String($0) }
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == UInt64 {
        let result = sequence.map { String($0) }
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == Float {
        let strategy = self.encoder.output.configuration.floatStrategy
        
        let result = try sequence.map { (value) throws -> String in
            guard let field = String.floatingPointRepresentation(value, strategy: strategy) else {
                let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The `Float` value \(value) couldn't be transformed to a String following the encoding strategy: \(strategy)")
                throw EncodingError.invalidValue(sequence, context)
            }
            return field
        }
        
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == Double {
        let strategy = self.encoder.output.configuration.floatStrategy
        
        let result = try sequence.map { (value) throws -> String in
            guard let field = String.floatingPointRepresentation(value, strategy: strategy) else {
                let context: EncodingError.Context = .init(codingPath: self.codingPath, debugDescription: "The `Double` value \(value) couldn't be transformed to a String following the encoding strategy: \(strategy)")
                throw EncodingError.invalidValue(sequence, context)
            }
            return field
        }
        
        try self.encodeNext(record: result, from: sequence)
    }
    
    func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element == String {
        let result: [String]
        
        switch sequence {
        case let array as [String]:
            result = array
        default:
            result = Array(sequence)
        }
        
        try self.encodeNext(record: result, from: sequence)
    }
    
    public func nestedContainer<NestedKey:CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        return self.encoder.container(keyedBy: keyType)
    }
    
    public func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return self.encoder.unkeyedContainer()
    }
}
