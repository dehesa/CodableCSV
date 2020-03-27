/// The coding key used to identify encoding/decoding containers.
internal struct DecodingKey: CodingKey {
    /// The integer value of the coding key.
    let index: Int
    /// Designated initializer.
    init(_ index: Int) {
        self.index = index
    }
    
    init?(intValue: Int) {
        guard intValue >= 0 else { return nil }
        self.init(intValue)
    }
    
    init?(stringValue: String) {
        guard let intValue = Int(stringValue) else { return nil }
        self.init(intValue)
    }
    
    var stringValue: String {
        return String(self.index)
    }
    
    var intValue: Int? {
        self.index
    }
}
