<p align="center">
    <img src="Assets/CodableCSV.svg" alt="Codable CSV"/>
</p>

[CodableCSV](https://github.com/dehesa/CodableCSV) allows you to read and write CSV files row-by-row or through Swift's Codable interface.

![Swift 5.1](https://img.shields.io/badge/Swift-5.1-orange.svg) ![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-lightgrey.svg) [![License](http://img.shields.io/:license-mit-blue.svg)](http://doge.mit-license.org) [![Build Status](https://travis-ci.com/dehesa/CodableCSV.svg?branch=master)](https://travis-ci.com/dehesa/CodableCSV)

This framework provides:

-   Row-by-row CSV reader & writer.
-   Codable interface.
-   Support for multiple inputs/outputs (in-memory, file system, binary socket, etc.).
-   CSV encoding & configuration inference (e.g. what field/row delimiters are being used).
-   Multiplatform support with no dependencies.

# Usage

To use this library, you need to add it to you project (through SPM or Cocoapods) and import it.

```swift
import CodableCSV
```

There are two ways to use [CodableCSV](https://github.com/dehesa/CodableCSV):

1. as an active row-by-row and field-by-field reader or writer.
2. through Swift's `Codable` interface.

The _active entities_ (reference types) provide _imperative_ control on how to read or write CSV data.

<details><summary><code>CSVReader</code>.</summary><p>

A `CSVReadder` reads CSV data and lets you access each CSV row as an array of `String`s:

-   row-by-row.

    ```swift
    let reader = try CSVReader(fileURL: ...)
    while let row = try reader.parseRow() {
        // Do something with the row: [String]
    }
    ```

-   with `Sequence` syntax.

    ```swift
    let reader = try CSVReader(data: ...)
    for row in reader {
        // Do something with the row: [String]
    }
    ```

    Please note the `Sequence` syntax (i.e. `IteratorProtocol`) doesn't throw errors; therefore if the CSV data is invalid, the previous code will crash your program. If you don't control the origin of the CSV data, use the `parseRow()` function instead.

A `CSVReader` are able to read the following input sources:

-   `String`.

    ```swift
    let reader = try CSVReader(string: "A,B,C\n D,E,F\n G,H,I\n")
    ```

-   `Data`.

    ```swift
    let reader = try CSVReader(data: Data(...))
    ```

-   A file `URL`.

    ```swift
    let reader = try CSVReader(fileURL: URL(...))
    ```

During initialization, an optional `Configuration` structure may be provided. These configuration values lets you tweak the parsing process.

```swift
let reader = try CSVReader(data: ..., configuration: ...)
```

`CSVReader` accept the following configuration properties:

-   `encoding` (default: `nil`) specify the CSV file encoding.

    This `String.Encoding` value specify how each underlying byte is represented (e.g. `.utf8`, `.utf32littleEndian`, etc.). If it is `nil`, the library will try to figure out the file encoding through the file's [Byte Order Marker](https://en.wikipedia.org/wiki/Byte_order_mark). If the file doesn't contain a BOM, `.utf8` is presumed.

-   `delimiters` (default: `(field: ",", row: "\n")`) specify the field and row delimiters.

    CSV fields are separated within a row with _field delimiters_ (commonly a "comma"). CSV rows are separated through _row delimiters_ (commonly a "line feed"). You can specify any unicode scalar, `String` value, or `nil` for unknown delimiters.

-   `headerStrategy` (default: `.none`) indicates whether the CSV data has a header row or not.

    CSV files may contain an optional header row at the very beginning. This configuration value lets you specify whether the file has a header row or not, or whether you want the library to figure it out.

-   `trimStrategy` (default: `.none`) trims the given characters at the beginning and end of each parsed row and field.

-   `presample` (default: `false`) indicates whether the CSV data should be completely loaded into memory before parsing begins.

    Loading all data into memory may provide faster iteration for small to medium size files, since you get rid of the overhead of managing an `InputStream`.

There is a convenience initializer letting you specify configuration values within a closure during initialization:

```swift
let reader = CSVReader(data: ...) {
    $0.encoding = .utf8
    $0.delimiters.row = .custom("~")
    $0.headerStrategy = .firstLine
    $0.trimStrategy = .whitespaces
}
```

</details>

<details><summary><code>CSVWriter</code>.</summary><p>

#warning("Complete me")

</details>

The CSV encoders/decoders provided by this library let you use Swift's `Codable` declarative approach.

<details><summary><code>CSVDecoder</code>.</summary><p>

```swift
let decoder = CSVDecoder()
decoder.delimiters = (.comma, .lineFeed)
let result = try decoder.decode(CustomType.self, from: data)
```

</details>

<details><summary><code>CSVEncoder</code>.</summary><p>

#warning("Complete me")

</details>

# Roadmap

<p align="center">
<img src="Assets/Roadmap.svg" alt="Roadmap"/>
</p>
