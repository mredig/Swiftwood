import XCTest
@testable import Swiftwood
typealias log = Swiftwood

/**
 Important note for anyone running tests is that they, by nature, many cannot really be automated. Some will need manual verification that what is logged will appear in
 the console (siphoned off into `ManualSwiftwoodTests`) Perhaps some test system will work someday, but that time is not now. 
 */
class SwiftwoodTests: XCTestCase {
	override func tearDown() {
		super.tearDown()

		log.clearDestinations()
		log.testingVerbosity = false

		do {
			try FileManager.default.removeItem(at: logFolder())
		} catch where (error as NSError).code == 4 {
			// do nothing, this is fine
		} catch {
			print("Error removing log folder from test run: \(error)")
		}
	}

	func logFolder() throws -> URL {
		let cacheFolder = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
		let logFolder = cacheFolder.appendingPathComponent("logs")
		return logFolder
	}

	func captureStdOutLine(alsoPrint: Bool = true, _ block: @escaping () throws -> Void) async throws -> String {
		guard
			let stdoutStr = try await captureStdOut(lineCount: 1, block).first
		else { throw SimpleError(message: "No stdout content") }
		return stdoutStr
	}

	func captureStdOut(lineCount: Int = 1, alsoPrint: Bool = true, _ block: @escaping () throws -> Void) async throws -> [String] {
		let pipe = Pipe()
		let originalStdOut = dup(STDOUT_FILENO)
		dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

		let bytes = pipe.fileHandleForReading.bytes

		try block()

		dup2(originalStdOut, STDOUT_FILENO)
		close(originalStdOut)

		var buffer: [String] = []

		for try await value in bytes.lines {
			buffer.append(value)
			if alsoPrint {
				print(value)
			}
			guard buffer.count == lineCount else { continue }
			break
		}

		return buffer
	}

	struct CensoredPassword: CensoredLogItem, RawRepresentable, CustomStringConvertible {
		let rawValue: String

		var description: String { rawValue }
	}

	struct CensoredKey: CensoredLogItem, RawRepresentable, CustomStringConvertible {
		let rawValue: String

		var description: String { rawValue }
		var censoredDescription: String {
			guard
				rawValue.count > 10,
				let start = rawValue.index(rawValue.endIndex, offsetBy: -3, limitedBy: rawValue.startIndex)
			else { return "***" }
			return "***" + String(rawValue[start..<rawValue.endIndex])
		}
	}

	struct SimpleError: Error {
		let message: String
	}
}
