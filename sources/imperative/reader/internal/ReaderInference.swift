extension Delimiter.Scalars {
  /// Closure accepting a scalar and returning a Boolean indicating whether the scalar (and subsquent unicode scalars from the input) form a delimiter.
  /// - parameter scalar: The scalar that may start a delimiter.
  /// - throws: `CSVError<CSVReader>` exclusively.
  typealias Checker = (_ scalar: Unicode.Scalar) throws -> Bool

  /// Creates a field delimiter identifier closure.
  /// - parameter buffer: A unicode character buffer containing further characters to parse.
  /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
  /// - returns: A closure which given the targeted unicode character and the buffer and iterrator, returns a Boolean indicating whether there is a field delimiter.
  func makeFieldMatcher(buffer: CSVReader.ScalarBuffer, decoder: @escaping CSVReader.ScalarDecoder) -> Self.Checker {
    Self._makeMatcher(delimiter: self.field, buffer: buffer, decoder: decoder)
  }

  /// Creates a row delimiter identifir closure.
  /// - parameter buffer: A unicode character buffer containing further characters to parse.
  /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
  /// - returns: A closure which given the targeted unicode character and the buffer and iterrator, returns a Boolean indicating whether there is a row delimiter.
  func makeRowMatcher(buffer: CSVReader.ScalarBuffer, decoder: @escaping CSVReader.ScalarDecoder) -> Self.Checker {
    guard self.row.count > 1 else {
      return Self._makeMatcher(delimiter: self.row.first!, buffer: buffer, decoder: decoder)
    }

    let delimiters = self.row.sorted { $0.count < $1.count }
    let maxScalars = delimiters.last!.count

    // For optimization sake, a delimiter proofer is built for a single value scalar.
    if maxScalars == 1 {
      return { [dels = delimiters.map { $0.first! }] in dels.contains($0) }
      // For optimization sake, a delimiter proofer is built for two unicode scalars.
    } else if maxScalars == 2 {
      return { [storage = Unmanaged.passUnretained(buffer), decoder,
                singles = delimiters.compactMap { ($0.count == 1) ? $0.first! : nil },
                doubles = delimiters.compactMap { ($0.count == 2) ? ($0[0], $0[1]) : nil }] (firstScalar) in
        if singles.contains(firstScalar) { return true }
        return try storage._withUnsafeGuaranteedRef {
          guard let secondScalar = try $0.next() ?? decoder() else { return false }
          for (first, second) in doubles where first==firstScalar && second==secondScalar { return true }
          $0.preppend(scalar: secondScalar)
          return false
        }
      }
    } else {
      return { [storage = Unmanaged.passUnretained(buffer), decoder] (firstScalar) in
        try storage._withUnsafeGuaranteedRef {
          var tmp: [Unicode.Scalar] = Array()

          loop: for del in delimiters {
            var iterator = del.makeIterator()
            guard firstScalar == iterator.next().unsafelyUnwrapped else { continue loop }

            var b = 0
            while let delimiterScalar = iterator.next() {
              let scalar: UnicodeScalar
              if tmp.endIndex > b {
                scalar = tmp[b]
              } else if let decodedScalar = try $0.next() ?? decoder() {
                scalar = decodedScalar
                tmp.append(scalar)
              } else {
                break loop
              }

              guard scalar == delimiterScalar else { continue loop }
              b &+= 1
            }
            return true
          }

          $0.preppend(scalars: tmp)
          return false
        }
      }
    }
  }
}

private extension Delimiter.Scalars {
  /// Creates a delimiter identifier closure.
  /// - parameter delimiter: The value to be checked for.
  /// - parameter buffer: A unicode character buffer containing further characters to parse.
  /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
  static func _makeMatcher(delimiter: [Unicode.Scalar], buffer: CSVReader.ScalarBuffer, decoder: @escaping CSVReader.ScalarDecoder) -> Self.Checker {
    assert(!delimiter.isEmpty)
    let count = delimiter.count
    let first = delimiter.first.unsafelyUnwrapped

    // For optimizations sake, a delimiter proofer is built for a single unicode scalar.
    if count == 1 {
      return { $0 == first }
    }

    let storage = Unmanaged.passUnretained(buffer)
    let second = delimiter[1]

    // For optimizations sake, a delimiter proofer is built for two unicode scalars.
    if count == 2 {
      return { [decoder] in
        guard first == $0 else { return false }
        return try storage._withUnsafeGuaranteedRef {
          guard let scalar = try $0.next() ?? decoder() else { return false }
          guard second == scalar else {
            $0.preppend(scalar: scalar)
            return false
          }
          return true
        }
      }
    }

    // For completion sake, a delimiter proofer is build for +2 unicode scalars. CSV files with multiscalar delimiters are very very rare.
    let delimiterIterator = delimiter.makeIterator()
    return { [decoder] in
      var iterator = delimiterIterator
      guard iterator.next().unsafelyUnwrapped == $0 else { return false }

      return try storage._withUnsafeGuaranteedRef {
        var tmp: [Unicode.Scalar] = Array()
        tmp.reserveCapacity(count)

        while let delimiterScalar = iterator.next() {
          guard let scalar = try $0.next() ?? decoder() else {
            storage._withUnsafeGuaranteedRef { $0.preppend(scalars: tmp) }
            return false
          }

          tmp.append(scalar)
          guard scalar == delimiterScalar else {
            storage._withUnsafeGuaranteedRef { $0.preppend(scalars: tmp) }
            return false
          }
        }

        return true
      }
    }
  }
}

extension CSVReader {
  /// Tries to infer both the field and row delimiter from the raw data.
  /// - parameter field: The field delimiter specified by the user.
  /// - parameter row: The row delimiter specified by the user.
  /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
  /// - parameter buffer: Small buffer use to store `Unicode.Scalar` values that have been read from the input, but haven't yet been processed.
  /// - throws: `CSVError<CSVReader>` exclusively.
  /// - todo: Implement the field and row inferences.
  static func inferDelimiters(field: Delimiter.Field, row: Delimiter.Row, decoder: ScalarDecoder, buffer: ScalarBuffer) throws -> Delimiter.Scalars {
    switch (field.isKnown, row.isKnown) {
    case (true, true):
      guard let delimiters = Delimiter.Scalars(field: field.scalars, row: row.scalars) else {
        throw Error._invalidDelimiters(field: field, row: row)
      }
      return delimiters
    default: throw Error._unsupportedInference()
    }
  }
}

fileprivate extension CSVReader.Error {
  /// Error raised when the field and row delimiters are the same.
  /// - parameter delimiter: The indicated field and row delimiters.
  static func _invalidDelimiters(field: Delimiter.Field, row: Delimiter.Row) -> CSVError<CSVReader> {
    CSVError(.invalidConfiguration,
             reason: "The field and row delimiters cannot be the same.",
             help: "Set different delimiters for fields and rows.",
             userInfo: ["Field delimiter": field.scalars, "Row delimiters": row.scalars])
  }
  /// Delimiter inference is not yet implemented.
  static func _unsupportedInference() -> CSVError<CSVReader> {
    CSVError(.invalidConfiguration,
             reason: "Delimiter inference is not yet supported by this library",
             help: "Specify a concrete delimiter or get in contact with the maintainer")
  }
}
