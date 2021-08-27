import Foundation

extension CSVReader: Failable {
  /// Reader status indicating whether there are remaning lines to read, the CSV has been completely parsed, or an error occurred and no further operation shall be performed.
  public enum Status {
    /// The CSV file hasn't been completely parsed.
    case active
    /// There are no more rows to read. The EOF has been reached.
    case finished
    /// An error has occurred and no further operations shall be performed with the reader instance.
    case failed(CSVError<CSVReader>)
  }

  /// The type of error raised by the CSV reader.
  public enum Error: Int {
    /// Some of the configuration values provided are invalid.
    case invalidConfiguration = 1
    /// The CSV data is invalid.
    case invalidInput = 2
//    /// The inferral process to figure out delimiters or header row status was unsuccessful.
//    case inferenceFailure = 3
    /// The input stream failed.
    case streamFailure = 4
  }

  public static var errorDomain: String {
    "Reader"
  }

  public static func errorDescription(for failure: Error) -> String {
    switch failure {
    case .invalidConfiguration: return "Invalid configuration"
//    case .inferenceFailure: return "Inference failure"
    case .invalidInput: return "Invalid input"
    case .streamFailure: return "Stream failure"
    }
  }
}

extension CSVReader {
  /// Private configuration variables for the CSV reader.
  struct Settings {
    /// The unicode scalar delimiters for fields and rows.
    let delimiters: Delimiter.Scalars
    /// The unicode scalar used as encapsulator and escaping character (when printed two times).
    let escapingScalar: Unicode.Scalar?
    /// The characters set to be trimmed at the beginning and ending of each field.
    let trimCharacters: CharacterSet
    /// Optimization constant used to overcome ObjC overhead.
    let isTrimNeeded: Bool

    /// Creates the inmutable reader settings from the user provided configuration values.
    /// - parameter configuration: The configuration values provided by the API user.
    /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
    /// - parameter buffer: Small buffer use to store `Unicode.Scalar` values that have been read from the input, but haven't yet been processed.
    /// - throws: `CSVError<CSVReader>` exclusively.
    init(configuration: Configuration, decoder: ScalarDecoder, buffer: ScalarBuffer) throws {
      // 1. Figure out the field and row delimiters.
      self.delimiters = try CSVReader.inferDelimiters(field: configuration.delimiters.field, row: configuration.delimiters.row, decoder: decoder, buffer: buffer)
      // 2. Set the escaping scalar.
      self.escapingScalar = configuration.escapingStrategy.scalar
      // 3. Set the trim characters set.
      self.trimCharacters = configuration.trimStrategy
      // 4. Optimize the trim characters check (to avoid ObjC overhead).
      self.isTrimNeeded = !self.trimCharacters.isEmpty
      // 5. If there are trim characters, ensure they are not delimiters or the escaping scalar.
      guard self.isTrimNeeded else { return }
      // 6. Ensure trim character set doesn't contain the field delimiter.
      guard self.delimiters.field.allSatisfy({ !self.trimCharacters.contains($0) }) else {
        throw Error._invalidTrimCharacters(self.trimCharacters, field: self.delimiters.field)
      }
      // 7. Ensure trim character set doesn't contain the row delimiter.
      guard self.delimiters.row.allSatisfy({ $0.allSatisfy { !self.trimCharacters.contains($0) } }) else {
        throw Error._invalidTrimCharacters(self.trimCharacters, row: self.delimiters.row)
      }
      // 8. Ensure trim character set does not include escaping scalar
      if let escapingScalar = self.escapingScalar, self.trimCharacters.contains(escapingScalar) {
        throw Error._invalidTrimCharacters(self.trimCharacters, escapingScalar: escapingScalar)
      }
    }
  }
}

fileprivate extension CSVReader.Error {
  /// Error raised when a delimiter (whether row or field) is included in the trim character set.
  /// - parameter trimCharacters: The character set selected from trimming.
  /// - parameter field: The delimiter contained within the trim characters.
  static func _invalidTrimCharacters(_ trimCharacters: CharacterSet, field: [Unicode.Scalar]) -> CSVError<CSVReader> {
    CSVError(.invalidConfiguration,
             reason: "The trim character set includes the field delimiter.",
             help: "Remove the delimiter scalars from the trim character set.",
             userInfo: ["Field delimiter": field, "Trim characters": trimCharacters])
  }
  /// Error raised when a delimiter (whether row or field) is included in the trim character set.
  /// - parameter trimCharacters: The character set selected from trimming.
  /// - parameter row: The delimiter contained within the trim characters.
  static func _invalidTrimCharacters(_ trimCharacters: CharacterSet, row: Set<[Unicode.Scalar]>) -> CSVError<CSVReader> {
    CSVError(.invalidConfiguration,
             reason: "The trim character set includes the field delimiter.",
             help: "Remove the delimiter scalars from the trim character set.",
             userInfo: ["Row delimiter": row, "Trim characters": trimCharacters])
  }
  /// Error raised when the escaping scalar has been included in the trim character set.
  /// - parameter trimCharacters: The character set selected for trimming.
  /// - parameter escapingScalar: The selected escaping scalar.
  static func _invalidTrimCharacters(_ trimCharacters: CharacterSet, escapingScalar: Unicode.Scalar) -> CSVError<CSVReader> {
    CSVError(.invalidConfiguration,
             reason: "The trim characters set includes the escaping scalar.",
             help: "Remove the escaping scalar from the trim characters set.",
             userInfo: ["Escaping scalar": escapingScalar, "Trim characters": trimCharacters])
  }
}
