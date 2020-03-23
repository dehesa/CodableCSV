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

> `CodableCSV` can _encode to_ or _decode from_ `String`s, `Data` blobs, or CSV files (represented by `URL` addresses).

# Usage

To use this library, you need to:

<ul>
<details><summary>Add <code>CodableCSV</code> to your project.</summary><p>

You can choose to add the library through SPM or Cocoapods:

-   [SPM](https://github.com/apple/swift-package-manager/tree/master/Documentation) (Swift Package Manager).

    ```swift
    // swift-tools-version:5.1
    import PackageDescription

    let package = Package(
        /* Your package name, supported platforms, and generated products go here */
        dependencies: [ .package(url: "https://github.com/dehesa/CodableCSV.git", .upToNextMinor(from: "0.5.0")) ],
        targets: [ .target(name: /* Your target name here */, dependencies: ["CodableCSV"]) ]
    )
    ```

-   Cocoapods.

    ```
    pod 'CodableCSV', '~> 0.5.0'
    ```

</p></details>

<details><summary>Import <code>CodableCSV</code> in the file that needs it.</summary><p>

```swift
import CodableCSV
```

</p></details>
</ul>

There are two ways to use this library:

1. as an active row-by-row and field-by-field reader or writer.
2. through Swift's `Codable` interface.

## Active Decoding/Encoding

The _active entities_ provide imperative control on how to read or write CSV data.

<ul>
<details><summary><code>CSVReader</code>.</summary><p>

A `CSVReadder` parses CSV data from a given input (`String`, or `Data`, or file) and returns CSV rows as a `String`s array. `CSVReader` can be used at a _high-level_, in which case it parses an input completely; or at a _low-level_, in which each row is decoded when requested.

-   Complete input parsing.

    ```swift
    let data: Data = ...
    let result = try CSVReader.parse(input: data)

    // `result` lets you access the CSV headers, all CSV rows, or access a specific row/record. For example:
    let headers = result.headers  // [String]
    let content = result.rows     // [[String]]
    let fieldA = result[row: 2, field: "Age"]  // String? (crash if the row index are out of bounds)
    let fieldB = result[row: 3, field: 2]      // String  (crash if the row or field index are out of bounds)
    ```

-   Row-by-row parsing.

    ```swift
    let string = """
        numA,numB,numC
        1,2,3
        4,5,6
        """
    let reader = try CSVReader(input: string) { $0.headerStrategy = .firstLine }

    let headers = reader.headers      // ["numA", "numB", "numC"]
    let rowA = try reader.parseRow()  // ["1", "2", "3"]
    let rowB = try reader.parseRow()  // ["4", "5", "6"]
    ```

    Alternatively you can use the `parseRecord()` function which also returns the next CSV row, but it wraps the result in a convenience structure. This structure lets you access each field with the header name (as long as the `headerStrategy` is marked with `.firstLine`).

    ```swift
    let reader = try CSVReader(input: string) { $0.headerStrategy = .firstLine }

    let headers = reader.headers      // ["numA", "numB", "numC"]

    let recordA = try reader.parseRecord()
    let rowA = recordA.row            // ["1", "2", "3"]
    let firstField = recordA[0]       // "1"
    let secondField = recordA["numB"] // "2"

    let recordB = try reader.parseRecord()
    ```

-   `Sequence` syntax parsing.

    ```swift
    let reader = try CSVReader(input: URL(...), configuration: ...)
    for row in reader {
        // Do something with the row: [String]
    }
    ```

    Please note the `Sequence` syntax (i.e. `IteratorProtocol`) doesn't throw errors; therefore if the CSV data is invalid, the previous code will crash. If you don't control the CSV data origin, use `parseRow()` instead.

### Reader Configuration

`CSVReader` accepts the following configuration properties:

-   `encoding` (default: `nil`) specify the CSV file encoding.

    This `String.Encoding` value specify how each underlying byte is represented (e.g. `.utf8`, `.utf32littleEndian`, etc.). If it is `nil`, the library will try to figure out the file encoding through the file's [Byte Order Marker](https://en.wikipedia.org/wiki/Byte_order_mark). If the file doesn't contain a BOM, `.utf8` is presumed.

-   `delimiters` (default: `(field: ",", row: "\n")`) specify the field and row delimiters.

    CSV fields are separated within a row with _field delimiters_ (commonly a "comma"). CSV rows are separated through _row delimiters_ (commonly a "line feed"). You can specify any unicode scalar, `String` value, or `nil` for unknown delimiters.

-   `headerStrategy` (default: `.none`) indicates whether the CSV data has a header row or not.

    CSV files may contain an optional header row at the very beginning. This configuration value lets you specify whether the file has a header row or not, or whether you want the library to figure it out.

-   `trimStrategy` (default: empty set) trims the given characters at the beginning and end of each parsed field.

    The trim characters are applied for the escaped and unescaped fields.

-   `presample` (default: `false`) indicates whether the CSV data should be completely loaded into memory before parsing begins.

    Loading all data into memory may provide faster iteration for small to medium size files, since you get rid of the overhead of managing an `InputStream`.

The configuration values are set during initialization and can be passed to the `CSVReader` instance through a structure or with a convenience closure syntax:

```swift
let reader = CSVReader(input: ...) {
    $0.encoding = .utf8
    $0.delimiters.row = "\r\n"
    $0.headerStrategy = .firstLine
    $0.trimStrategy = .whitespaces
}
```

</p></details>

<details><summary><code>CSVWriter</code>.</summary><p>

A `CSVWriter` encodes CSV information into a specified target (i.e. a `String`, or `Data`, or a file). It can be used at a _high-level_, by encoding completely a prepared set of information; or at a _low-level_, in which case rows or fields can be writen individually.

-   Complete CSV rows serialization.

    ```swift
    let input = [
        ["numA", "numB", "name"        ],
        ["1"   , "2"   , "Marcos"      ],
        ["4"   , "5"   , "Marine-Anaïs"]
    ]
    let data   = try CSVWriter.serialize(rows: input, into: Data.self)
    let string = try CSVWriter.serialize(rows: input, into: String.self)
    let file   = try CSVWriter.serialize(rows: input, into: URL("~/Desktop/Test.csv")!, append: false)
    ```

-   Row-by-row encoding.

    ```swift
    let writer = try CSVWriter(fileURL: URL("~/Desktop/Test.csv")!, append: false)
    for row in input {
        try writer.write(row: row)
    }
    try writer.endFile()
    ```

    Alternatively, you may write directly to a buffer in memory and access its `Data` representation.

    ```swift
    let writer = try CSVWriter { $0.headers = input[0] }
    for row in input.dropFirst() {
        try writer.write(row: row)
    }
    try writer.endFile()
    let result = try writer.data()
    ```

-   Field-by-field encoding.

    ```swift
    let writer = try CSVWriter(fileURL: URL("~/Desktop/Test.csv")!, append: false)
    try writer.write(row: input[0])

    input[1].forEach {
        try writer.write(field: field)
    }
    try writer.endRow()

    try writer.write(fields: input[2])
    try writer.endRow()

    try writer.endFile()
    ```

    `CSVWriter` has a wealth of low-level imperative APIs, that let you write one field, several fields at a time, end a row, write an empty row, etc.

    > Please notice that a CSV requires all rows to have the same amount of fields.

    `CSVWriter` enforces this by throwing an error when you try to write more the expected amount of fields, or filling a row with empty fields when you call `endRow()` but not all fields has been written.

### Writer Configuration

`CSVWriter` accepts the following configuration properties:

-   `delimiters` (default: `(field: ",", row: "\n")`) specify the field and row delimiters.

    CSV fields are separated within a row with _field delimiters_ (commonly a "comma"). CSV rows are separated through _row delimiters_ (commonly a "line feed"). You can specify any unicode scalar, `String` value, or `nil` for unknown delimiters.

-   `headers` (default: `[]`) indicates whether the CSV data has a header row or not.

    CSV files may contain an optional header row at the very beginning. If this configuration value is empty, no header row is writen.

-   `encoding` (default: `nil`) specify the CSV file encoding.

    This `String.Encoding` value specify how each underlying byte is represented (e.g. `.utf8`, `.utf32littleEndian`, etc.). If it is `nil`, the library will try to figure out the file encoding through the file's [Byte Order Marker](https://en.wikipedia.org/wiki/Byte_order_mark). If the file doesn't contain a BOM, `.utf8` is presumed.

-   `bomStrategy` (default: `.convention`) indicates whether a Byte Order Marker will be included at the beginning of the CSV representation.

    The OS convention is that BOMs are never writen, except when `.utf16`, `.utf32`, or `.unicode` string encodings are specified. You could however indicate that you always want the BOM writen (`.always`) or that is never writer (`.never`).

The configuration values are set during initialization and can be passed to the `CSWriter` instance through a structure or with a convenience closure syntax:

```swift
let writer = CSWriter(fileURL: ...) {
    $0.delimiters.row = "\r\n"
    $0.headers = ["Name", "Age", "Pet"]
    $0.encoding = .utf8
    $0.bomStrategy = .never
}
```

</p></details>
</ul>

## `Codable`'s Decoder/Encoder

The encoders/decoders provided by this library let you use Swift's `Codable` declarative approach to encode/decode CSV data.

<ul>
<details><summary><code>CSVDecoder</code>.</summary><p>

`CSVDecoder` transforms CSV data into a Swift type conforming to `Decodable`. The decoding process is very simple and it only requires creating a decoding instance and call its `decode` function passing the `Decodable` type and the input data.

```swift
let decoder = CSVDecoder()
let result = try decoder.decode(CustomType.self, from: data)
```

### Decoder Configuration

The decoding process can be tweaked by specifying configuration values at initialization time. `CSVDecoder` accepts the [same configuration values as `CSVReader`](#Reader-Configuration) plus the following ones:

-   `floatStrategy` (default: `.throw`) defines how to deal with non-conforming floating-point numbers (such as `NaN`, or `+Infinity`).

-   `decimalStrategy` (default: `.locale(nil)`) indicates how decimal numbers are decoded (from `String` to `Decimal` value).

-   `dataStrategy` (default: `.deferredToDate`) specify the strategy to use when decoding dates.

-   `dataStrategy` (default: `.base64`) specify the strategy to use when decoding data blobs.

-   `bufferingStrategy` (default: `.keepAll`) tells the decoder how to cache previously decoded CSV rows.

    Caching rows allow random access through `KeyedDecodingContainer`s.

The configuration values can be set during `CSVDecoder` initialization or at any point before the `decode` function is called.

```swift
let decoder = CSVDecoder {
    $0.encoding = .utf8
    $0.delimiters.field = "\t"
    $0.headerStrategy = .firstLine
    $0.bufferingStrategy = .ordered
}

decoder.decimalStratey = .custom {
    let value = try Float(from: $0)
    return Decimal(value)
}
```

</p></details>

<details><summary><code>CSVEncoder</code>.</summary><p>

#warning("TODO:")

</p></details>
</ul>

## Tips Using `Codable`

`Codable` is fairly easy to use and most Swift standard library types already conform to it. However, sometimes it is tricky to get custom types to comply to `Codable` for very specific functionality. That is why I am leaving here some tips and advices concerning its usage:

<ul>
<details><summary>Basic adoption.</summary><p>

`Codable` is just a type alias for `Decodable` and `Encodable`. When a custom type conforms to `Codable`, the type is stating that it has the ability to decode itself from and encode itself to a external representation. Which representation depends on the decoder or encoder chosen. Foundation provides support for [JSON and Property Lists](https://developer.apple.com/documentation/foundation/archives_and_serialization), but the community provide many other formats, such as: [YAML](https://github.com/jpsim/Yams), [XML](https://github.com/MaxDesiatov/XMLCoder), [BSON](https://github.com/OpenKitten/BSON), and CSV (through this library).

Lets see a regular CSV encoding/decoding usage through `Codable`'s interface. Let's suppose we have a list of students formatted in a CSV file:

```swift
let data = """
name,age,hasPet
John,22,true
Marine,23,false
Alta,24,true
"""
```

In Swift, a _student_ has the following structure:

```swift
struct Student: Codable {
    var name: String
    var age: Int
    var hasPet: Bool
}
```

To decode the CSV data, we just need to create a decoder and call `decode` on it passing the given data.

```swift
let decoder = CSVDecoder { $0.headerStrategy = .firstLine }
let students = try decoder.decode([Student], from: data)
```

The inverse process (from Swift to CSV) is very similar (and simple).

```swift
let encoder = CSVEncoder { $0.headerStraty = .firstLine }
let newData = try encoder.encode(students)
```

</p></details>

<details><summary>Specific behavior for CSV data.</summary><p>

When encoding/decoding CSV data, it is important to keep several points in mind:

</p>
<ul>
<details><summary>Default behavior requires a CSV with a headers row.</summary><p>

The default behavior (i.e. not including `init(from:)` and `encode(to:)`) rely on the existance of the synthesized `CodingKey`s whose `stringValue`s are the property names. For these properties to match any CSV field, the CSV data must contain a _headers row_ at the very beginning. If your CSV doesn't contain a _headers row_, you can specify coding keys with integer values representing the field index.

```swift
struct Student: Codable {
    var name: String
    var age: Int
    var hasPet: Bool

    private CodingKeys: Int, CodingKey {
        case name = 0
        case age = 1
        case hasPet = 2
    }
}
```

> Using integer coding keys has the added benefit of better encoder/decoder performance. By explicitly indicating the field index, you let the decoder skip the functionality of matching coding keys string values to headers.

</p></details>
<details><summary>A CSV is a long list of records/rows.</summary><p>

CSV formatted data is commonly used with flat hierarchies (e.g. a list of students, a list of car models, etc.). Nested structures, such as the ones found in JSON files, are not supported by default in CSV implementations (e.g. a list of users, where each user has a list of services she uses, and each service has a list of the user's configuration values).

You can support complex structures in CSV, but you would have to flatten the hierarchy in a single model or build a custom encoding/decoding process. This process would make sure there is always a maximum of two keyed/unkeyed containers.

As an example, we can create a nested structure for a school with students who own pets.

```swift
struct School: Codable {
    let students: [Student]
}

struct Student: Codable {
    var name: String
    var age: Int
    var pet: Pet
}

struct Pet: Codable {
    var nickname: String
    var gender: Gender

    enum Gender: Codable {
        case male, female
    }
}
```

By default the previous example wouldn't work. If you want to keep the nested structure, you need to overwrite the custom `init(from:)` implementation (to support `Decodable`).

```swift
extension School {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            self.student.append(try container.decode(Student.self))
        }
    }
}

extension Student {
    init(from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: CustomKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.age = try container.decode(Int.self, forKey: .age)
        self.pet = try decoder.singleValueContainer.decode(Pet.self)
    }
}

extension Pet {
    init(from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: CustomKeys.self)
        self.nickname = try container.decode(String.self, forKey: .nickname)
        self.gender = try container.decode(Gender.self, forKey: .gender)
    }
}

extension Pet.Gender {
    init(from decoder: Decoder) throws {
        var container = try decoder.singleValueContainer()
        self = try container.decode(Int.self) == 1 ? .male : .female
    }
}

private CustomKeys: Int, CodingKey {
    case name = 0
    case age = 1
    case nickname = 2
    case gender = 3
}
```

You could have avoided building the initializers overhead by defining a flat structure such as:

```swift
struct Student: Codable {
    var name: String
    var age: Int
    var nickname: String
    var gender: Gender

    enum Gender: Int, Codable {
        case male = 1
        case female = 2
    }
}
```

</p></details>
</ul>

</details>

<details><summary>Configuration values and encoding/decoding strategies.</summary><p>

#warning("TODO:")

</p></details>

<details><summary>Performance advices.</summary><p>

#warning("TODO:")

</p></details>
</ul>

# Roadmap

<p align="center">
<img src="Assets/Roadmap.svg" alt="Roadmap"/>
</p>
