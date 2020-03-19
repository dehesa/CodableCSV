import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ReaderTests.allTests),
        testCase(WriterTests.allTests),
        testCase(DecodingRegularUsageTests.allTests),
        testCase(DecodingSinglesTests.allTests),
        testCase(DecodingWrappersTests.allTests)
    ]
}
#endif
