import Foundation

public class ConsoleLogDestination: SwiftwoodDestination {
	public var format = Swiftwood.Format()
	public var minimumLogLevel: Swiftwood.Level = .info
	public var logFilter: LogCategory.Filter = .none
	public var shouldCensor: Bool

	@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
	public var flushImmediately: Bool {
		get { _flushImmediately }
		set { _flushImmediately = newValue }
	}
	private var _flushImmediately = false

	public var maxBytesDisplayed: Int

	private let stdOut = FileHandle.standardOutput

	public init(maxBytesDisplayed: Int, shouldCensor: Bool = false) {
		self.maxBytesDisplayed = maxBytesDisplayed
		self.shouldCensor = shouldCensor
	}

	public func sendToDestination(_ entry: Swiftwood.LogEntry) {
		let formattedMessage = format.convertEntryToString(entry, censoring: shouldCensor)

		guard maxBytesDisplayed > 0 else {
			print(formattedMessage)
			return
		}

		guard
			let sectionEndIndex = formattedMessage.index(
				formattedMessage.startIndex,
				offsetBy: maxBytesDisplayed,
				limitedBy: formattedMessage.endIndex)
		else {
			print(formattedMessage)
			return
		}

		let firstXCharacters = formattedMessage[formattedMessage.startIndex..<sectionEndIndex]

		print(firstXCharacters + "... (too large to output in console)")
	}

	private func print(_ args: Any ..., terminator: String = "\n") {
		let stringified = args
			.map { String(describing: $0) }
			.joined(separator: " ")
			.appending(terminator)
			.utf8
		let data = Data(stringified)
		do {
			if #available(macOS 10.15.4, iOS 13.4, tvOS 13.4, *) {
				try stdOut.write(contentsOf: data)
			} else {
				stdOut.write(data)
			}
			if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
				if flushImmediately {
					try stdOut.synchronize()
				}
			}
		} catch {
			Swift.print("Error sending to stdout: \(error)")
			Swift.print(stringified)
		}
	}
}
