import Foundation

extension ShadowEncoder {
    /// Container that will hold one CSV record.
    internal final class EncodingRecordOrdered: RecordEncodingContainer, EncodingOrderedContainer {
        let codingKey: CSVKey
        private(set) var encoder: ShadowEncoder!
        
        init(encoder: ShadowEncoder) throws {
            fatalError()
            
//            self.encoder = try encoder.subEncoder(adding: self)
        }
        
        /// The number of elements encoded into the container.
        public var count: Int {
            #warning("TODO")
            fatalError()
        }
        
        public func encodeNil() throws {
            #warning("TODO")
            fatalError()
        }
        
        
        public func encode<T:Encodable>(_ value: T) throws {
            #warning("TODO")
            fatalError()
        }

        public func encodeConditional<T>(_ object: T) throws where T: AnyObject & Encodable {
            #warning("TODO: Figure out if there is a good way to do this.")
            return try self.encode(object)
        }
        
        public func encode<T:Sequence>(contentsOf sequence: T) throws where T.Element : Encodable {
            #warning("TODO")
            fatalError()
        }
        
        public func nestedContainer<NestedKey:CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            #warning("TODO")
            fatalError()
        }

        public func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            #warning("TODO")
            fatalError()
        }
    }
}

extension ShadowEncoder.EncodingRecordOrdered {
    func encodeNext(record: [String], from sequence: Any) throws {
        #warning("TODO")
        fatalError()
    }
    
    func encodeNext(field: String, from value: Any) throws {
        #warning("TODO")
        fatalError()
    }
}
