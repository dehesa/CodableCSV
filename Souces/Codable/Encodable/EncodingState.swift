import Foundation

extension ShadowEncoder {
    /// The steps on the encoding chain that has been taken.
    internal enum State: CodingState {
        /// Nothing has been yet selected.
        case overview
        
        init(containers: [CodingContainer]) throws {
            var state: State = .overview
            let codingPath: [CodingKey] = containers.map { $0.codingKey }
            
            for container in containers {
                #warning("TODO")
//                switch container {
//
//                }
            }
            
            self = state
        }
    }
}
