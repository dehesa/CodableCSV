import Foundation

/// List of test data used intensively around the test bundle.
enum TestData {
    /// Arrays of CSV rows.
    enum Arrays {
        /// A small amount of rows with four fields each.
        static let genericNoHeader = [
            ["1", "Marcos", "Spain", "99"],
            ["2", "Marine-Anaïs", "France", "88"],
            ["3", "Alex", "Germany", "77"],
            ["4", "Pei", "China", "66"]
        ]
        
        /// A small amount of rows with four fields each and a header row (at the beginning).
        static let genericHeader = [
            ["seq", "Name", "Country", "Number Pair"]
        ] + genericNoHeader
        
        /// A bunch of rows each one containing an edge case.
        static let edgeCases = [
            ["", "Marcos", "Spain", "99"],
            ["2", "Marine-Anaïs", "France", ""],
            ["", "", "", ""],
            ["4", "Pei", "China", "\"\n\""],
            ["", "", "", "\"\r\n\""],
            ["5", "\"A\rh,me\nd\"", "Egypt", "\"\r\""]
        ]
    }
}
