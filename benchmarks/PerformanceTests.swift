import XCTest
import CodableCSV

/// Tests checking the regular encoding usage.
final class PerformanceTests: XCTestCase {
  override func setUp() {
    self.continueAfterFailure = false
  }
}

extension PerformanceTests {
  /// Tests the encoding of an empty.
  func testEmptyFile() throws {
    //        XCTSkipUnless(<#T##expression: Bool##Bool#>, <#T##message: String?##String?#>)
    #if !DEBUG
    print("Hello RELEASE")
    #endif
  }
}
