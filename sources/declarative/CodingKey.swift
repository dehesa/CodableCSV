/// The coding key used to identify encoding/decoding containers.
internal struct IndexKey: CodingKey {
    /// The integer value of the coding key.
    let index: Int
    /// Designated initializer.
    init(_ index: Int) { self.index = index }
    
    init?(intValue: Int) {
        guard intValue >= 0 else { return nil }
        self.init(intValue)
    }
    
    init?(stringValue: String) {
        guard let intValue = Int(stringValue) else { return nil }
        self.init(intValue)
    }
    
    var stringValue: String { String(self.index) }
    var intValue: Int? { self.index }
}

/// Coding key used to represent a key with both an integer value and a string value.
internal struct NameKey: CodingKey {
    /// The integer value of the given key.
    let index: Int
    /// The name for the given key.
    let name: String
    /// Designated initializer.
    init(index: Int, name: String) {
        self.index = index
        self.name = name
    }
    
    init?(intValue: Int) { nil }
    init?(stringValue: String) { nil }
    
    var stringValue: String { self.name }
    var intValue: Int? { self.index }
}

/// Coding key used to represent an invalid branch on a coding path.
internal struct InvalidKey: CodingKey {
    init() {}
    init?(intValue: Int) { nil }
    init?(stringValue: String) { nil }
    
    var stringValue: String { "" }
    var intValue: Int? { nil }
}
