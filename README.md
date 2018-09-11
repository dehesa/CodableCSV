Codable CSV
===========

CodableCSV allows you to read and write CSV files row-by-row or through Swift's Codable interface.

This framework provides:
- Active row-by-row (field-by-field) CSV reader & writer.
- Encodable & Decodable interfaces.
- Support for multiple inputs/outputs: in-memory, file system, binary socket, etc.
- CSV encoding & configuration inferral (e.g. what field/row delimiters are being used).
- Multiplatform support & no dependencies.
- CSV Playground.

Installation
------------

This framework has no dependencies, which makes its installation trivial. The following installation processes are available:

- Grab the `.framework` for the platform of your choice from [the Github releases page](https://github.com/dehesa/CodableCSV/releases).
  1. Download the framework file to your computer.
  2. Drag-and-drop it within your project.
  3. If you are using Xcode, drag-and-drop the framework in `Linked Frameworks & Libraries`.
- Clone and build it with Xcode.
  1. Clone the git project: `git clone git@github.com:dehesa/CodableCSV.git`
  2. Open the `CodableCSV.xcworkspace` with Xcode.
  3. Select the build scheme for your targeted platform (e.g. `CSV [macOS]`).
  4. Product > Build (or keyboard shortcut `⌘+B`).
  5. Open the project's `Products` folder and drag-and-drop the built framework in your project (or right-click in it and `Show in Finder`).
- Add this framework to your dependencies with the Swift Package Manager.
  1. TODO!
- Add this framework to your dependencies with Carthage.
  1. TODO!

Usage
-----

### Codable

Swift's Codable is one of the easiest way to interface with encoded files (e.g. JSON, PLIST, and now CSV). The process is usually pretty similar.

1. Create and encoder or decoder for your targeted file type.
	```swift
	let decoder = CSVDecoder()
	```
2. Optionally pass any configuration you want to the decoder.
	```swift
	decoder.delimiters = (.comma, .lineFeed)   // These are the default
	```
3. Decode the file (from an already preloaded datablob or a file in the file system) into a given type.
	```swift
	let file = try decoder.decode(MyCSVFile.self, from: data)
	```
	
	The type passed as argument must implement `Codable` (only `Decodable` in this case).
   Most Swift Standard Library types already conform to `Codable`. Thus, if you just want to retrieve the data raw from a CSV file, you  could have done:
	```swift
	let rows = try decoder.decode([[String]].self, from: data).
	```
   You would get all the rows in the CSV file. Each row containing an array of fields.

For custom types:

1. Define the `Decodable` implementation.
2. Implement the `init(from:)` initializer if needed (many times you won't need to).
3. Remember that a CSV file is made of rows and each row contains several fields (how many will depend on the file).
   This means that you should only query for two levels of nested containers.

```swift
struct School: Decodable {
	// The custom CSV file is a list of all the students.
	let people: [Student]
}

struct Student: Decodable {
	let name: String
	let age: Int
	let hasPet: Bool
}
```

The previous example will work if the CSV file has a header row and the header titles match exactly the property names (`name`, `age`, and `hasPet`). A more efficient and detailed implementation:

```swift
struct Student: Decodable {
	let name: String
	let age: Int
	let hasPet: Bool

	init(from decoder: Decoder) {
		var row = try decoder.unkeyedContainer
		self.name = try row.decode(String.self)
		self.age = try row.decode(Int.self)
		self.hasPet = try row.decode(Boolean.self)
	}
}
```


### CSV Reader

### CSV Writer

Roadmap
-------

- [x] CSVReader.
- [x] CSVReader generic tests.
- [x] Generic & Specific Configurations.
- [x] Decodable.
- [x] Decodable generic tests.
- [x] SuperDecoder functionality and inmutable decoding chain.
- [x] Support for Date, Data, and Decimal in Decodable.
- [x] CSVWriter.
- [x] CSVWriter generic tests.
- [ ] Encodable.
- [ ] Add File support everywhere (i.e. CSVReader, CSVWriter, Codable).
- [ ] Improve README.md.
- [ ] CSVReader inferrals.
- [ ] CSVReader edge cases tests.
- [ ] CSVWriter edge cases tests.
- [ ] Decodable edge cases tests.
- [ ] Encodable edge cases tests.
- [ ] Unlimited lookback in Decodable (unkeyed containers).
