import XCTest
@testable import Swiftwood

/**
 These tests are those that (at least thus far) I have not devised a way (read 'easy way') to verify automatically (could probably redirect `stdout` to a file, read it in,
 regex parse, and confirm...). In the mean time, these tests largely serve as templates by which you can manually run them and verify that they perform as expected.
 */
final class ManualSwiftwoodTests: SwiftwoodTests {
	/// ran into a runtime issue with trying to write to a non existant file in the automated variation while flusing immediately, so keeping this *for now*
	/// If there has been no problem with the automated variant before 12/2/24, go ahead and delete this test
	func testConsoleLoggingStdOut() throws {
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1, mode: .stdout(flushImmediately: false))
		consoleDestination.minimumLogLevel = .veryVerbose
		log.appendDestination(consoleDestination)
		log.appendDestination(try FilesDestination(
			logFolder: nil,
			fileformat: .formattedString
		))

		log.veryVerbose("Don't even worry")
		log.verbose("Something small happened")
		log.debug("Some minor update")
		log.info("Look at me")
		log.warning("uh oh")
		log.error("Failed successfully")
		log.critical("Aww fork! Shirt went down!")

		// manual verification - should resemble
		/*
		 12/10/2022 00:19:57.461 (🤎 VERY VERBOSE default) ManualSwiftwoodTests.swift testConsoleLoggingStdOut():18 - Don't even worry
		 12/10/2022 00:19:57.463 (💜 VERBOSE default) ManualSwiftwoodTests.swift testConsoleLoggingStdOut():19 - Something small happened
		 12/10/2022 00:19:57.464 (💚 DEBUG default) ManualSwiftwoodTests.swift testConsoleLoggingStdOut():20 - Some minor update
		 12/10/2022 00:19:57.464 (💙 INFO default) ManualSwiftwoodTests.swift testConsoleLoggingStdOut():21 - Look at me
		 12/10/2022 00:19:57.464 (💛 WARNING default) ManualSwiftwoodTests.swift testConsoleLoggingStdOut():22 - uh oh
		 12/10/2022 00:19:57.465 (❤️ ERROR default) ManualSwiftwoodTests.swift testConsoleLoggingStdOut():23 - Failed successfully
		 12/10/2022 00:19:57.465 (💔💔 CRITICAL default) ManualSwiftwoodTests.swift testConsoleLoggingStdOut():24 - Aww fork! Shirt went down!
		 */
	}

	func testBuildInfo() {
		log.testingVerbosity = true
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1)
		consoleDestination.format.parts.append(.staticText(" -- build: "))
		consoleDestination.format.parts.append(.buildInfo)

		log.appendDestination(consoleDestination)

		log.info("testttt")
		log.info("should be cached")

		log.buildInfoGenerator = {
			print("generated nil")
			return nil
		}

		log.info("should be nil")
		log.info("should be cached")

		log.buildInfoGenerator = {
			print("generated toot")
			return "toot"
		}
		log.info("should be toot")
		log.info("should be cached")

		// manual verification - should resemble (21501 will change as xcode versions increase)
		/*
		 12/10/2022 00:19:35.699 (💙 INFO default) ManualSwiftwoodTests.swift testBuildInfo():44 - testttt -- build: 21501
		 cache hit
		 12/10/2022 00:19:35.700 (💙 INFO default) ManualSwiftwoodTests.swift testBuildInfo():45 - should be cached -- build: 21501
		 generated nil
		 12/10/2022 00:19:35.700 (💙 INFO default) ManualSwiftwoodTests.swift testBuildInfo():52 - should be nil -- build: nil
		 cache hit
		 12/10/2022 00:19:35.700 (💙 INFO default) ManualSwiftwoodTests.swift testBuildInfo():53 - should be cached -- build: nil
		 generated toot
		 12/10/2022 00:19:35.700 (💙 INFO default) ManualSwiftwoodTests.swift testBuildInfo():59 - should be toot -- build: toot
		 cache hit
		 12/10/2022 00:19:35.700 (💙 INFO default) ManualSwiftwoodTests.swift testBuildInfo():60 - should be cached -- build: toot
		 */
	}

	func testCensoring() {
		let censoredConsoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1, shouldCensor: true)
		let unCensoredConsoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1, shouldCensor: false)
		log.appendDestination(censoredConsoleDestination)
		log.appendDestination(unCensoredConsoleDestination, replicationOption: .appendAlike)

		let password = CensoredPassword(rawValue: "shouldbeconditionallycensored")
		let key = CensoredKey(rawValue: "thisisalongkey")

		let numericalValue = 3
		log.info("a", numericalValue, password, key)

		// manual verification - should resemble
		/*
		 12/10/2022 00:18:55.502 (💙 INFO default) ManualSwiftwoodTests.swift testCensoring():88 - a 3 CensoredPassword: **CENSORED** ***key
		 12/10/2022 00:18:55.502 (💙 INFO default) ManualSwiftwoodTests.swift testCensoring():88 - a 3 shouldbeconditionallycensored thisisalongkey
		 */
	}

	func testCategoryFilteringNone() {
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1)
		consoleDestination.logFilter = .none
		log.appendDestination(consoleDestination)

		log.info("fake doors!", category: .fakeDoors)
		log.info("real doors!", category: .realDoors)
		log.info("real fake doors!", category: .realFakeDoors)
		// manual verification - should resemble

		/*
		 12/10/2022 00:17:56.503 (💙 INFO fakeDoors) ManualSwiftwoodTests.swift testCategoryFilteringNone():102 - fake doors!
		 12/10/2022 00:17:56.504 (💙 INFO realDoors) ManualSwiftwoodTests.swift testCategoryFilteringNone():103 - real doors!
		 12/10/2022 00:17:56.504 (💙 INFO realFakeDoors) ManualSwiftwoodTests.swift testCategoryFilteringNone():104 - real fake doors!
		 */
	}

	func testCategoryFilteringAllow() {
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1)
		consoleDestination.logFilter = .allow([.realFakeDoors])
		log.appendDestination(consoleDestination)

		log.info("fake doors!", category: .fakeDoors)
		log.info("real doors!", category: .realDoors)
		log.info("real fake doors!", category: .realFakeDoors)

		// manual verification - should resemble
		/*
		 12/10/2022 00:18:34.809 (💙 INFO realFakeDoors) ManualSwiftwoodTests.swift testCategoryFilteringAllow():121 - real fake doors!
		 */
	}

	func testCategoryFilteringBlock() {
		let consoleDestination = ConsoleLogDestination(maxBytesDisplayed: -1)
		consoleDestination.logFilter = .block([.realFakeDoors])
		log.appendDestination(consoleDestination)

		log.info("fake doors!", category: .fakeDoors)
		log.info("real doors!", category: .realDoors)
		log.info("real fake doors!", category: .realFakeDoors)

		// manual verification - should resemble
		/*
		 12/10/2022 00:18:45.063 (💙 INFO fakeDoors) ManualSwiftwoodTests.swift testCategoryFilteringBlock():134 - fake doors!
		 12/10/2022 00:18:45.064 (💙 INFO realDoors) ManualSwiftwoodTests.swift testCategoryFilteringBlock():135 - real doors!
		 */
	}
}


fileprivate extension LogCategory {
	static let fakeDoors: LogCategory = "fakeDoors"
	static let realDoors: LogCategory = "realDoors"
	static let realFakeDoors: LogCategory = "realFakeDoors"
}
