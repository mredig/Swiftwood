import XCTest
@testable import Swiftwood

/// These tests should correctly work with automation.
final class AutomatedSwiftwoodTests: SwiftwoodTests {
	func testDestinationAdditionsForfeit() {
		let consoleDestinationA = ConsoleLogDestination(maxBytesDisplayed: -1)
		let consoleDestinationB = ConsoleLogDestination(maxBytesDisplayed: -1)

		log.appendDestination(consoleDestinationA)
		log.appendDestination(consoleDestinationB, replicationOption: .forfeitToAlike)

		XCTAssertTrue(log.destinations.contains(where: { $0 === consoleDestinationA }))
		XCTAssertFalse(log.destinations.contains(where: { $0 === consoleDestinationB }))
		XCTAssertEqual(log.destinations.count, 1)
	}

	func testDestinationAdditionsReplace() {
		let consoleDestinationA = ConsoleLogDestination(maxBytesDisplayed: -1)
		let consoleDestinationB = ConsoleLogDestination(maxBytesDisplayed: -1)

		log.appendDestination(consoleDestinationA)
		log.appendDestination(consoleDestinationB, replicationOption: .replaceAlike)

		XCTAssertFalse(log.destinations.contains(where: { $0 === consoleDestinationA }))
		XCTAssertTrue(log.destinations.contains(where: { $0 === consoleDestinationB }))
		XCTAssertEqual(log.destinations.count, 1)
	}

	func testDestinationAdditionsAppend() {
		let consoleDestinationA = ConsoleLogDestination(maxBytesDisplayed: -1)
		let consoleDestinationB = ConsoleLogDestination(maxBytesDisplayed: -1)

		log.appendDestination(consoleDestinationA)
		log.appendDestination(consoleDestinationB, replicationOption: .appendAlike)

		XCTAssertTrue(log.destinations.contains(where: { $0 === consoleDestinationA }))
		XCTAssertTrue(log.destinations.contains(where: { $0 === consoleDestinationB }))
		XCTAssertEqual(log.destinations.count, 2)
	}

	func testFilesDestination() throws {
		let logFolder = try logFolder()
		let fileDestination = try FilesDestination(logFolder: logFolder, fileformat: .formattedString, minimumLogLevel: .info)
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1)
		consoleDestination.minimumLogLevel = .verbose

		log.appendDestination(fileDestination)
		log.appendDestination(consoleDestination)

		var logContent: [URL] = []
		logContent = try FileManager.default.contentsOfDirectory(at: logFolder, includingPropertiesForKeys: nil)
		XCTAssertTrue(logContent.isEmpty)

		let message = "test file destination"
		log.info(message)
		logContent = try FileManager.default.contentsOfDirectory(at: logFolder, includingPropertiesForKeys: nil)
		XCTAssertEqual(1, logContent.count)

		let consoleOnly = "test console destination"
		log.verbose(consoleOnly)
		log.debug(consoleOnly)
		logContent = try FileManager.default.contentsOfDirectory(at: logFolder, includingPropertiesForKeys: nil)
		XCTAssertEqual(1, logContent.count)
	}

	func testFilesDestinationFormattedString() throws {
		let logFolder = try logFolder()
		let fileDestination = try FilesDestination(logFolder: logFolder, fileformat: .formattedString, minimumLogLevel: .info)
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1)

		log.appendDestination(fileDestination)
		log.appendDestination(consoleDestination)

		var logContent: [URL] = []

		let message = "test file destination"
		log.info(message)
		logContent = try FileManager.default.contentsOfDirectory(at: logFolder, includingPropertiesForKeys: nil)
		XCTAssertEqual(1, logContent.count)

		let logFileURL = logContent[0]
		let logFileData = try Data(contentsOf: logFileURL)

		let logFile = try XCTUnwrap(String(data: logFileData, encoding: .utf8))
		XCTAssertTrue(logFile.contains(message))
		XCTAssertTrue(logFile.contains("(💙 INFO default) AutomatedSwiftwoodTests.swift testFilesDestinationFormattedString()"))
	}

	func testFilesDestinationJSON() throws {
		let logFolder = try logFolder()
		let fileDestination = try FilesDestination(logFolder: logFolder, fileformat: .json, minimumLogLevel: .info)
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1)

		log.appendDestination(fileDestination)
		log.appendDestination(consoleDestination)

		var logContent: [URL] = []

		let message = "test file destination"
		log.info(message)
		logContent = try FileManager.default.contentsOfDirectory(at: logFolder, includingPropertiesForKeys: nil)
		XCTAssertEqual(1, logContent.count)

		let logFileURL = logContent[0]
		let logFileData = try Data(contentsOf: logFileURL)

		let logFile = try JSONDecoder().decode(CodableLogEntry.self, from: logFileData)
		XCTAssertEqual(message, logFile.message.first)
		XCTAssertEqual(Swiftwood.Level.info.level, logFile.logLevel)
	}

	func testFilesDestinationCensored() throws {
		let logFolder = try logFolder()
		let fileDestination = try FilesDestination(logFolder: logFolder, shouldCensor: true)
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1)

		log.appendDestination(fileDestination)
		log.appendDestination(consoleDestination)

		var logContent: [URL] = []

		let message = "test file destination"
		let password = CensoredPassword(rawValue: "password!1234")
		log.info(message, password)
		logContent = try FileManager.default.contentsOfDirectory(at: logFolder, includingPropertiesForKeys: nil)
		XCTAssertEqual(1, logContent.count)

		let logFileURL = logContent[0]
		let logFileData = try Data(contentsOf: logFileURL)

		let logFile = try JSONDecoder().decode(CodableLogEntry.self, from: logFileData)
		XCTAssertEqual(message, logFile.message.first)
		XCTAssertEqual(password.censoredDescription, logFile.message.last)
		XCTAssertNotEqual(password.rawValue, logFile.message.last)
		XCTAssertEqual(Swiftwood.Level.info.level, logFile.logLevel)
	}

	func testFilesDestinationUncensored() throws {
		let logFolder = try logFolder()
		let fileDestination = try FilesDestination(logFolder: logFolder, shouldCensor: false)
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1)

		log.appendDestination(fileDestination)
		log.appendDestination(consoleDestination)

		var logContent: [URL] = []

		let message = "test file destination"
		let password = CensoredPassword(rawValue: "password!1234")
		log.info(message, password)
		logContent = try FileManager.default.contentsOfDirectory(at: logFolder, includingPropertiesForKeys: nil)
		XCTAssertEqual(1, logContent.count)

		let logFileURL = logContent[0]
		let logFileData = try Data(contentsOf: logFileURL)

		let logFile = try JSONDecoder().decode(CodableLogEntry.self, from: logFileData)
		XCTAssertEqual(message, logFile.message.first)
		XCTAssertEqual(password.rawValue, logFile.message.last)
		XCTAssertNotEqual(password.censoredDescription, logFile.message.last)
		XCTAssertEqual(Swiftwood.Level.info.level, logFile.logLevel)
	}

	func testFileDestination() throws {
		let logFolder = try logFolder()

		let logFile = logFolder
			.appendingPathComponent("biglogfile")
			.appendingPathExtension("log")

		var fileDestination = try FileDestination(maxSize: 128, shouldCensor: false, outputFile: logFile)

		log.appendDestination(fileDestination)

		log.veryVerbose("Don't even worry")
		log.verbose("Something small happened")
		log.debug("Some minor update")
		log.info("Look at me")
		log.warning("uh oh")
		log.error("Failed successfully")
		log.critical("Aww fork! Shirt went down!")

		var expected = [logFile] + (1...3)
			.map { logFile.appendingPathExtension("\($0)") }
		var contents = try FileManager.default.contentsOfDirectory(at: logFolder, includingPropertiesForKeys: nil)

		XCTAssertEqual(Set(expected), Set(contents))

		fileDestination = try FileDestination(maxSize: 8_000_000, shouldCensor: false, outputFile: logFile)
		log.appendDestination(fileDestination, replicationOption: .replaceAlike)

		log.veryVerbose("Don't even worry")
		log.verbose("Something small happened")
		log.debug("Some minor update")
		log.info("Look at me")
		log.warning("uh oh")
		log.error("Failed successfully")
		log.critical("Aww fork! Shirt went down!")

		expected = [logFile] + (1...3)
			.map { logFile.appendingPathExtension("\($0)") }
		contents = try FileManager.default.contentsOfDirectory(at: logFolder, includingPropertiesForKeys: nil)

		XCTAssertEqual(Set(expected), Set(contents))

		fileDestination = try FileDestination(maxSize: 128, shouldCensor: false, outputFile: logFile)
		log.appendDestination(fileDestination, replicationOption: .replaceAlike)

		log.veryVerbose("Don't even worry")
		log.verbose("Something small happened")
		log.debug("Some minor update")
		log.info("Look at me")
		log.warning("uh oh")
		log.error("Failed successfully")
		log.critical("Aww fork! Shirt went down!")

		expected = [logFile] + (1...7)
			.map { logFile.appendingPathExtension("\($0)") }
		contents = try FileManager.default.contentsOfDirectory(at: logFolder, includingPropertiesForKeys: nil)

		XCTAssertEqual(Set(expected), Set(contents))
	}

	func testConsoleLoggingStdOut() async throws {
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1, mode: .stdout(flushImmediately: false))
		consoleDestination.minimumLogLevel = .veryVerbose
		log.appendDestination(consoleDestination)
		log.appendDestination(try FilesDestination(
			logFolder: nil,
			fileformat: .formattedString
		))

		let veryVerboseMessage = "Don't even worry"
		var result = try await captureStdOutLine {
			log.veryVerbose(veryVerboseMessage)
		}
		XCTAssertTrue(result.hasSuffix(veryVerboseMessage))
		XCTAssertTrue(result.contains("(🤎 VERY VERBOSE default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():"))

		let verboseMessage = "Something small happened"
		result = try await captureStdOutLine {
			log.verbose(verboseMessage)
		}
		XCTAssertTrue(result.hasSuffix(verboseMessage))
		XCTAssertTrue(result.contains("(💜 VERBOSE default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():"))


		let debugMessage = "Some minor update"
		result = try await captureStdOutLine {
			log.debug(debugMessage)
		}
		XCTAssertTrue(result.hasSuffix(debugMessage))
		XCTAssertTrue(result.contains("(💚 DEBUG default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():"))

		let infoMessage = "Look at me"
		result = try await captureStdOutLine {
			log.info(infoMessage)
		}
		XCTAssertTrue(result.hasSuffix(infoMessage))
		XCTAssertTrue(result.contains("(💙 INFO default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():"))

		let warningMessage = "uh oh"
		result = try await captureStdOutLine {
			log.warning(warningMessage)
		}
		XCTAssertTrue(result.hasSuffix(warningMessage))
		XCTAssertTrue(result.contains("(💛 WARNING default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():"))

		let errorMessage = "uh oh"
		result = try await captureStdOutLine {
			log.error(errorMessage)
		}
		XCTAssertTrue(result.hasSuffix(errorMessage))
		XCTAssertTrue(result.contains("(❤️ ERROR default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():"))

		let criticalMessage = "Aww fork! Shirt went down!"
		result = try await captureStdOutLine {
			log.critical(criticalMessage)
		}
		XCTAssertTrue(result.hasSuffix(criticalMessage))
		XCTAssertTrue(result.contains("(💔💔 CRITICAL default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():"))

		// manual verification - should resemble
		/*
		 12/10/2022 00:19:57.461 (🤎 VERY VERBOSE default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():18 - Don't even worry
		 12/10/2022 00:19:57.463 (💜 VERBOSE default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():19 - Something small happened
		 12/10/2022 00:19:57.464 (💚 DEBUG default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():20 - Some minor update
		 12/10/2022 00:19:57.464 (💙 INFO default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():21 - Look at me
		 12/10/2022 00:19:57.464 (💛 WARNING default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():22 - uh oh
		 12/10/2022 00:19:57.465 (❤️ ERROR default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():23 - Failed successfully
		 12/10/2022 00:19:57.465 (💔💔 CRITICAL default) AutomatedSwiftwoodTests.swift testConsoleLoggingStdOut():24 - Aww fork! Shirt went down!
		 */
	}

	func testConsoleLoggingPrint() async throws {
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1, mode: .print)
		consoleDestination.minimumLogLevel = .veryVerbose
		log.appendDestination(consoleDestination)
		log.appendDestination(try FilesDestination(
			logFolder: nil,
			fileformat: .formattedString
		))

		let veryVerboseMessage = "Don't even worry"
		var result = try await captureStdOutLine {
			log.veryVerbose(veryVerboseMessage)
		}
		XCTAssertTrue(result.hasSuffix(veryVerboseMessage))
		XCTAssertTrue(result.contains("(🤎 VERY VERBOSE default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():"))

		let verboseMessage = "Something small happened"
		result = try await captureStdOutLine {
			log.verbose(verboseMessage)
		}
		XCTAssertTrue(result.hasSuffix(verboseMessage))
		XCTAssertTrue(result.contains("(💜 VERBOSE default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():"))


		let debugMessage = "Some minor update"
		result = try await captureStdOutLine {
			log.debug(debugMessage)
		}
		XCTAssertTrue(result.hasSuffix(debugMessage))
		XCTAssertTrue(result.contains("(💚 DEBUG default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():"))

		let infoMessage = "Look at me"
		result = try await captureStdOutLine {
			log.info(infoMessage)
		}
		XCTAssertTrue(result.hasSuffix(infoMessage))
		XCTAssertTrue(result.contains("(💙 INFO default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():"))

		let warningMessage = "uh oh"
		result = try await captureStdOutLine {
			log.warning(warningMessage)
		}
		XCTAssertTrue(result.hasSuffix(warningMessage))
		XCTAssertTrue(result.contains("(💛 WARNING default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():"))

		let errorMessage = "uh oh"
		result = try await captureStdOutLine {
			log.error(errorMessage)
		}
		XCTAssertTrue(result.hasSuffix(errorMessage))
		XCTAssertTrue(result.contains("(❤️ ERROR default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():"))

		let criticalMessage = "Aww fork! Shirt went down!"
		result = try await captureStdOutLine {
			log.critical(criticalMessage)
		}
		XCTAssertTrue(result.hasSuffix(criticalMessage))
		XCTAssertTrue(result.contains("(💔💔 CRITICAL default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():"))

		// manual verification - should resemble
		/*
		 12/10/2022 00:19:57.461 (🤎 VERY VERBOSE default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():18 - Don't even worry
		 12/10/2022 00:19:57.463 (💜 VERBOSE default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():19 - Something small happened
		 12/10/2022 00:19:57.464 (💚 DEBUG default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():20 - Some minor update
		 12/10/2022 00:19:57.464 (💙 INFO default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():21 - Look at me
		 12/10/2022 00:19:57.464 (💛 WARNING default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():22 - uh oh
		 12/10/2022 00:19:57.465 (❤️ ERROR default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():23 - Failed successfully
		 12/10/2022 00:19:57.465 (💔💔 CRITICAL default) AutomatedSwiftwoodTests.swift testConsoleLoggingPrint():24 - Aww fork! Shirt went down!
		 */
	}

	struct SampleCustomType {
		let value = "boo"
	}
	func testContextOutputFromContextCustomType() async throws {
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1, mode: .print)
		consoleDestination.minimumLogLevel = .veryVerbose
		log.appendDestination(consoleDestination)

		let format = Swiftwood.Format(
			parts: [
				.logLevel,
				.staticText(" "),
				.message,
				.staticText(" "),
				.context
			])
		consoleDestination.format = format
		let customConversion = Swiftwood.Format.ContextFormatter.custom { context in
			if let custom = context as? SampleCustomType {
				return "MEGA SAMPLE SUCCESS: \(custom.value)"
			} else {
				return Swiftwood.Format.ContextFormatter.attemptDictionaryCast.formatContext(context)
			}
		}

		let context = SampleCustomType()

		let stringSuffix = "Context: SampleCustomType(value: \"boo\")"
		let customSuffix = "MEGA SAMPLE SUCCESS: boo"

		let veryVerboseMessage = "simple message"

		consoleDestination.format.contextFormatter = .convertToString
		var result = try await captureStdOutLine {
			log.info(veryVerboseMessage, context: context)
		}
		XCTAssertTrue(result.hasSuffix(stringSuffix))

		consoleDestination.format.contextFormatter = .attemptDictionaryCast
		result = try await captureStdOutLine {
			log.info(veryVerboseMessage, context: context)
		}
		XCTAssertTrue(result.hasSuffix(stringSuffix))

		consoleDestination.format.contextFormatter = customConversion
		result = try await captureStdOutLine {
			log.info(veryVerboseMessage, context: context)
		}
		XCTAssertTrue(result.hasSuffix(customSuffix))
	}

	func testContextOutputFromContextString() async throws {
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1, mode: .print)
		consoleDestination.minimumLogLevel = .veryVerbose
		log.appendDestination(consoleDestination)

		let format = Swiftwood.Format(
			parts: [
				.logLevel,
				.staticText(" "),
				.message,
				.staticText(" "),
				.context
			])
		consoleDestination.format = format
		let customConversion = Swiftwood.Format.ContextFormatter.custom { context in
			if let custom = context as? SampleCustomType {
				return "MEGA SAMPLE SUCCESS: \(custom.value)"
			} else {
				return Swiftwood.Format.ContextFormatter.attemptDictionaryCast.formatContext(context)
			}
		}

		let context = "barfoo"

		let stringSuffix = "barfoo"

		let veryVerboseMessage = "simple message"

		consoleDestination.format.contextFormatter = .convertToString
		var result = try await captureStdOutLine {
			log.info(veryVerboseMessage, context: context)
		}
		XCTAssertTrue(result.hasSuffix(stringSuffix))

		consoleDestination.format.contextFormatter = .attemptDictionaryCast
		result = try await captureStdOutLine {
			log.info(veryVerboseMessage, context: context)
		}
		XCTAssertTrue(result.hasSuffix(stringSuffix))

		consoleDestination.format.contextFormatter = customConversion
		result = try await captureStdOutLine {
			log.info(veryVerboseMessage, context: context)
		}
		XCTAssertTrue(result.hasSuffix(stringSuffix))
	}

	func testContextOutputFromContextDictionary() async throws {
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1, mode: .print)
		consoleDestination.minimumLogLevel = .veryVerbose
		log.appendDestination(consoleDestination)

		let format = Swiftwood.Format(
			parts: [
				.logLevel,
				.staticText(" "),
				.message,
				.staticText(" "),
				.context
			])
		consoleDestination.format = format
		let customConversion = Swiftwood.Format.ContextFormatter.custom { context in
			if let custom = context as? SampleCustomType {
				return "MEGA SAMPLE SUCCESS: \(custom.value)"
			} else {
				return Swiftwood.Format.ContextFormatter.attemptDictionaryCast.formatContext(context)
			}
		}

		let contextA: [String: Any] = ["foo": CocoaError(.coderValueNotFound), "bar": 1234]

		let aStringSuffix = "]"
		let aStringContains1 = ##""bar": 1234"##
		let aStringContains2 = ##""foo": Foundation.CocoaError(_nsError: Error Domain=NSCocoaErrorDomain Code=4865 "The data couldn’t be read because it is missing.")"##
		let aDictionarySuffix = """
			Context:
				bar: 1234
				foo: CocoaError(_nsError: Error Domain=NSCocoaErrorDomain Code=4865 "The data couldn’t be read because it is missing.")
			"""

		let veryVerboseMessage = "simple message"

		consoleDestination.format.contextFormatter = .convertToString
		var result = try await captureStdOut(lineCount: 1) {
			log.info(veryVerboseMessage, context: contextA)
		}.joined(separator: "\n")
		XCTAssertTrue(result.contains(aStringContains1))
		XCTAssertTrue(result.contains(aStringContains2))
		XCTAssertTrue(result.hasSuffix(aStringSuffix))

		consoleDestination.format.contextFormatter = .attemptDictionaryCast
		result = try await captureStdOut(lineCount: 3) {
			log.info(veryVerboseMessage, context: contextA)
		}.joined(separator: "\n")
		XCTAssertTrue(result.hasSuffix(aDictionarySuffix))

		consoleDestination.format.contextFormatter = customConversion
		result = try await captureStdOut(lineCount: 3) {
			log.info(veryVerboseMessage, context: contextA)
		}.joined(separator: "\n")
		XCTAssertTrue(result.hasSuffix(aDictionarySuffix))
	}

	func testContextOutputFromContextNull() async throws {
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1, mode: .print)
		consoleDestination.minimumLogLevel = .veryVerbose
		log.appendDestination(consoleDestination)

		let format = Swiftwood.Format(
			parts: [
				.logLevel,
				.staticText(" "),
				.message,
				.staticText(" "),
				.context
			])
		consoleDestination.format = format
		let customConversion = Swiftwood.Format.ContextFormatter.custom { context in
			if let custom = context as? SampleCustomType {
				return "MEGA SAMPLE SUCCESS: \(custom.value)"
			} else {
				return Swiftwood.Format.ContextFormatter.attemptDictionaryCast.formatContext(context)
			}
		}

		let context: Int? = nil

		let veryVerboseMessage = "simple message"
		let stringSuffix = "\(veryVerboseMessage) "

		consoleDestination.format.contextFormatter = .convertToString
		var result = try await captureStdOutLine {
			log.info(veryVerboseMessage, context: context)
		}
		XCTAssertTrue(result.hasSuffix(stringSuffix))

		consoleDestination.format.contextFormatter = .attemptDictionaryCast
		result = try await captureStdOutLine {
			log.info(veryVerboseMessage, context: context)
		}
		XCTAssertTrue(result.hasSuffix(stringSuffix))

		consoleDestination.format.contextFormatter = customConversion
		result = try await captureStdOutLine {
			log.info(veryVerboseMessage, context: context)
		}
		XCTAssertTrue(result.hasSuffix(stringSuffix))
	}

}
