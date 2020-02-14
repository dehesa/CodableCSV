/// List of test data used intensively around the test bundle.
enum TestData {
    /// A CSV row representing a header row (4 fields).
    static let headers = ["seq", "Name", "Country", "Number Pair"]
    
    /// Small amount of regular CSV rows (4 fields per row).
    static let content = [
        ["1", "Marcos", "Spain", "99"],
        ["2", "Marine-Anaïs", "France", "88"],
        ["3", "Alex", "Germany", "77"],
        ["4", "Pei", "China", "66"]
    ]
    
    /// A bunch of rows each one containing an edge case.
    static let contentEdgeCases = [
        ["", "Marcos", "Spain", "99"],
        ["2", "Marine-Anaïs", "France", ""],
        ["", "", "", ""],
        ["4", "Pei", "China", "\"\n\""],
        ["", "", "", "\"\r\n\""],
        ["5", "\"A\rh,me\nd\"", "Egypt", "\"\r\""]
    ]
}
