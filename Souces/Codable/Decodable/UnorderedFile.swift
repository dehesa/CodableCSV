//import Foundation
//
//extension ShadowDecoder {
//    final class UnorderedFile<Key:CodingKey>: FileContainer, KeyedDecodingContainerProtocol {
//        /// The decoder that created this.
//        private unowned let decoder: ShadowDecoder
//        
//        let codingPath: [CodingKey]
//        
//        init(decoder: ShadowDecoder, reader: CSVReader, codingPath: [CodingKey]) {
//            self.decoder = decoder
//            self.codingPath = codingPath
//        }
//    }
//}
//
////var codingPath: [CodingKey] { get }
////var allKeys: [Self.Key] { get }
////func contains(_ key: Self.Key) -> Bool
////func decodeNil(forKey key: Self.Key) throws -> Bool
////func decode(_ type: Bool.Type, forKey key: Self.Key) throws -> Bool
////func decode(_ type: String.Type, forKey key: Self.Key) throws -> String
////func decode(_ type: Double.Type, forKey key: Self.Key) throws -> Double
////func decode(_ type: Float.Type, forKey key: Self.Key) throws -> Float
////func decode(_ type: Int.Type, forKey key: Self.Key) throws -> Int
////func decode(_ type: Int8.Type, forKey key: Self.Key) throws -> Int8
////func decode(_ type: Int16.Type, forKey key: Self.Key) throws -> Int16
////func decode(_ type: Int32.Type, forKey key: Self.Key) throws -> Int32
////func decode(_ type: Int64.Type, forKey key: Self.Key) throws -> Int64
////func decode(_ type: UInt.Type, forKey key: Self.Key) throws -> UInt
////func decode(_ type: UInt8.Type, forKey key: Self.Key) throws -> UInt8
////func decode(_ type: UInt16.Type, forKey key: Self.Key) throws -> UInt16
////func decode(_ type: UInt32.Type, forKey key: Self.Key) throws -> UInt32
////func decode(_ type: UInt64.Type, forKey key: Self.Key) throws -> UInt64
////func decode<T>(_ type: T.Type, forKey key: Self.Key) throws -> T where T : Decodable
////func decodeIfPresent(_ type: Bool.Type, forKey key: Self.Key) throws -> Bool?
////func decodeIfPresent(_ type: String.Type, forKey key: Self.Key) throws -> String?
////func decodeIfPresent(_ type: Double.Type, forKey key: Self.Key) throws -> Double?
////func decodeIfPresent(_ type: Float.Type, forKey key: Self.Key) throws -> Float?
////func decodeIfPresent(_ type: Int.Type, forKey key: Self.Key) throws -> Int?
////func decodeIfPresent(_ type: Int8.Type, forKey key: Self.Key) throws -> Int8?
////func decodeIfPresent(_ type: Int16.Type, forKey key: Self.Key) throws -> Int16?
////func decodeIfPresent(_ type: Int32.Type, forKey key: Self.Key) throws -> Int32?
////func decodeIfPresent(_ type: Int64.Type, forKey key: Self.Key) throws -> Int64?
////func decodeIfPresent(_ type: UInt.Type, forKey key: Self.Key) throws -> UInt?
////func decodeIfPresent(_ type: UInt8.Type, forKey key: Self.Key) throws -> UInt8?
////func decodeIfPresent(_ type: UInt16.Type, forKey key: Self.Key) throws -> UInt16?
////func decodeIfPresent(_ type: UInt32.Type, forKey key: Self.Key) throws -> UInt32?
////func decodeIfPresent(_ type: UInt64.Type, forKey key: Self.Key) throws -> UInt64?
////func decodeIfPresent<T>(_ type: T.Type, forKey key: Self.Key) throws -> T? where T : Decodable
////func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Self.Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey
////func nestedUnkeyedContainer(forKey key: Self.Key) throws -> UnkeyedDecodingContainer
////func superDecoder() throws -> Decoder
////func superDecoder(forKey key: Self.Key) throws -> Decoder
