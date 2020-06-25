import Foundation

extension CSVReader.Configuration {
    @available(*, deprecated, renamed: "trimStrategy")
    public var trimStrategry: CharacterSet {
        self.trimStrategy
    }
}

extension CSVEncoder.Configuration {
    @available(*, deprecated, renamed: "nonConformingFloatStrategy")
    public var floatStrategy: Strategy.NonConformingFloat {
        self.nonConformingFloatStrategy
    }
}

extension CSVDecoder.Configuration {
    @available(*, deprecated, renamed: "nonConformingFloatStrategy")
    public var floatStrategy: Strategy.NonConformingFloat {
        self.nonConformingFloatStrategy
    }
}
