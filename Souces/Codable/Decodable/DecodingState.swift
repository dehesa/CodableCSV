import Foundation

extension ShadowDecoder {
    /// The steps on the decoding chain that has been taken.
    internal enum State: CodingState {
        /// Nothing have been yet selected.
        case overview
        /// A collection of rows.
        case file(FileDecodingContainer)
        /// A record. In other words: a collection of fields/values.
        case record(RecordDecodingContainer)
        /// A single field/value.
        case field(ShadowDecoder.DecodingField)
        
        /// Initializes and verifies that the given container are in correct state.
        ///
        /// Correct state addresses the need for the decoding containers to be in their correct orders (e.g. file, record, field) and that there is only one file and record decoding containers.
        init(containers: [CodingContainer]) throws {
            var state: State = .overview
            let codingPath: [CodingKey] = containers.map { $0.codingKey }
            
            for container in containers {
                switch container {
                case is FileDecodingContainer:
                    guard case .overview = state else {
                        throw DecodingError.invalidContainer(codingPath: codingPath)
                    }
                    state = .file(container as! FileDecodingContainer)
                case is RecordDecodingContainer:
                    guard case .file(_) = state else {
                        throw DecodingError.invalidContainer(codingPath: codingPath)
                    }
                    state = .record(container as! RecordDecodingContainer)
                case is ShadowDecoder.DecodingField:
                    switch state {
                    case .record(_):
                        state = .field(container as! ShadowDecoder.DecodingField)
                    case .field(_):
                        break
                    default:
                        throw DecodingError.invalidContainer(codingPath: codingPath)
                    }
                case is WrapperDecodingContainer:
                    switch state {
                    case .overview:
                        guard container is ShadowDecoder.DecodingFileWrapper else {
                            throw DecodingError.invalidContainer(codingPath: codingPath)
                        }
                    case .file(_):
                        guard container is ShadowDecoder.DecodingRecordWrapper else {
                            throw DecodingError.invalidContainer(codingPath: codingPath)
                        }
                    case .record(_), .field(_):
                        throw DecodingError.invalidContainer(codingPath: codingPath)
                    }
                default:
                    throw DecodingError.invalidContainer(codingPath: codingPath)
                }
            }
            
            self = state
        }
    }
}
