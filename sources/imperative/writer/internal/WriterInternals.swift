extension CSVWriter: Failable {
  /// The type of error raised by the CSV writer.
  public enum Error: Int {
    /// Some of the configuration values provided are invalid.
    case invalidConfiguration = 1
    /// The CSV data is invalid.
    case invalidInput = 2
    /// The output stream failed.
    case streamFailure = 4
    /// The operation couldn't be carried or failed midway.
    case invalidOperation = 5
  }

  public static var errorDomain: String {
    "Writer"
  }

  public static func errorDescription(for failure: Error) -> String {
    switch failure {
    case .invalidConfiguration: return "Invalid configuration"
    case .invalidInput: return "Invalid input"
    case .streamFailure: return "Stream failure"
    case .invalidOperation: return "Invalid operation"
    }
  }
}

extension CSVWriter {
  /// Private configuration variables for the CSV writer.
  struct Settings {
    /// The unicode scalar delimiters for fields and rows.
    let delimiters: (field: [Unicode.Scalar], row: [Unicode.Scalar])
    /// The unicode scalar used as encapsulator and escaping character (when printed two times).
    let escapingScalar: Unicode.Scalar?
    /// Boolean indicating whether the received CSV contains a header row or not.
    let headers: [String]
    /// The encoding used to identify the underlying data.
    let encoding: String.Encoding

    /// Designated initializer taking generic CSV configuration (with possible unknown data) and making it specific to a CSV writer instance.
    /// - parameter configuration: The public CSV writer configuration variables.
    /// - throws: `CSVError<CSVWriter>` exclusively.
    init(configuration: CSVWriter.Configuration, encoding: String.Encoding) throws {
      // 1. The field and row delimiters must be defined and they cannot be the same.
      guard let delimiters = Delimiter.Scalars(field: configuration.delimiters.field.scalars, row: configuration.delimiters.row.scalars) else {
        throw Error._invalidDelimiters()
      }
      self.delimiters = (delimiters.field, delimiters.row.min {
        guard $0.count == $1.count else { return $0.count < $1.count }
        for (lhs, rhs) in zip($0, $1) where lhs != rhs { return lhs < rhs }
        return true
      }!)
      // 2. Copy all other values.
      self.escapingScalar = configuration.escapingStrategy.scalar
      self.headers = configuration.headers
      self.encoding = encoding
    }
  }
}

// MARK: -

fileprivate extension CSVWriter.Error {
  /// Error raised when the the field or/and row delimiters are invalid.
  static func _invalidDelimiters() -> CSVError<CSVWriter> {
    CSVError(.invalidConfiguration,
             reason: "The field and/or row delimiters are invalid.",
             help: "Both delimiters must contain at least contain a unicode scalar/character and they must be different to each other.")
  }
}

