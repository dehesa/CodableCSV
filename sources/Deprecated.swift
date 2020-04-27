import Foundation

extension CSVReader {
    @available(*, deprecated, renamed: "FileView")
    public typealias Output = FileView
    
    @available(*, deprecated, renamed: "readRecord()")
    public func parseRecord() throws -> Record? {
        try self.readRecord()
    }
    
    @available(*, deprecated, renamed: "readRow()")
    public func parseRow() throws -> [String]? {
        try self.readRow()
    }
    
    @available(*, deprecated, renamed: "decode(input:configuration:)")
    public static func parse<S>(input: S, configuration: Configuration = .init()) throws -> Output where S:StringProtocol {
        try self.decode(input: input, configuration: configuration)
    }
    
    @available(*, deprecated, renamed: "decode(rows:into:configuration:)")
    public static func parse(input: Data, configuration: Configuration = .init()) throws -> Output {
        try self.decode(input: input, configuration: configuration)
    }
    
    @available(*, deprecated, renamed: "decode(rows:into:configuration:)")
    public static func parse(input: URL, configuration: Configuration = .init()) throws -> Output {
        try self.decode(input: input, configuration: configuration)
    }
    
    @available(*, deprecated, renamed: "decode(rows:setter:)")
    public static func parse<S>(input: S, setter: (_ configuration: inout Configuration)->Void) throws -> Output where S:StringProtocol {
        try self.decode(input: input, setter: setter)
    }
    
    @available(*, deprecated, renamed: "decode(rows:into:setter:)")
    public static func parse(input: Data, setter: (_ configuration: inout Configuration)->Void) throws -> Output {
        try self.decode(input: input, setter: setter)
    }
    
    @available(*, deprecated, renamed: "decode(rows:into:append:setter:)")
    public static func parse(input: URL, setter: (_ configuration: inout Configuration)->Void) throws -> Output {
        try self.decode(input: input, setter: setter)
    }
}

extension CSVWriter {
    @available(*, deprecated, renamed: "encode(rows:into:configuration:)")
    public static func serialize<S:Sequence,C:Collection>(rows: S, configuration: Configuration = .init()) throws -> Data where S.Element==C, C.Element==String {
        try self.encode(rows: rows, into: Data.self, configuration: configuration)
    }
    
    @available(*, deprecated, renamed: "encode(rows:into:configuration:)")
    @inlinable public static func serialize<S:Sequence,C:Collection>(rows: S, into type: String.Type, configuration: Configuration = .init()) throws -> String where S.Element==C, C.Element==String {
        try self.encode(rows: rows, into: type, configuration: configuration)
    }
    
    @available(*, deprecated, renamed: "encode(rows:into:configuration:)")
    public static func serialize<S:Sequence,C:Collection>(rows: S, into fileURL: URL, append: Bool, configuration: Configuration = .init()) throws where S.Element==C, C.Element==String {
        try self.encode(rows: rows, into: fileURL, append: append, configuration: configuration)
    }
    
    @available(*, deprecated, renamed: "encode(rows:into:setter:)")
    public static func serialize<S:Sequence,C:Collection>(rows: S, setter: (_ configuration: inout Configuration) -> Void) throws -> Data where S.Element==C, C.Element==String {
        try self.encode(rows: rows, into: Data.self, setter: setter)
    }
    
    @available(*, deprecated, renamed: "encode(rows:into:setter:)")
    public static func serialize<S:Sequence,C:Collection>(rows: S, into type: String.Type, setter: (_ configuration: inout Configuration) -> Void) throws -> String where S.Element==C, C.Element==String {
        try self.encode(rows: rows, into: type, setter: setter)
    }
    
    @available(*, deprecated, renamed: "encode(rows:into:append:setter:)")
    public static func serialize<S:Sequence,C:Collection>(row: S, into fileURL: URL, append: Bool, setter: (_ configuration: inout Configuration) -> Void) throws where S.Element==C, C.Element==String {
        try self.encode(rows: row, into: fileURL, append: append, setter: setter)
    }
}
