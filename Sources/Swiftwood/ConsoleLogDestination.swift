import Foundation

public class ConsoleLogDestination: SwiftwoodDestination {
	public var format = Swiftwood.Format()
	public var minimumLogLevel: Swiftwood.Level = .info
	public var logFilter: LogCategory.Filter = .none
	public var shouldCensor: Bool

	public var mode: Mode
	public enum Mode {
		case print
		/// `flushImmediately` will only have any effect if used on the apple product generation of macOS 10.15 and iOS 13 and later.
		case stdout(flushImmediately: Bool)
	}

	public var maxBytesDisplayed: Int

	private let stdOut = FileHandle.standardOutput

	public static let defaultMode = {
		#if canImport(FoundationNetworking)
		Mode.stdout(flushImmediately: true)
		#else
		Mode.print
		#endif
	}()

	public init(maxBytesDisplayed: Int, shouldCensor: Bool = false, mode: Mode = ConsoleLogDestination.defaultMode) {
		self.maxBytesDisplayed = maxBytesDisplayed
		self.shouldCensor = shouldCensor
		self.mode = mode
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

	private func print(_ string: String) {
		switch mode {
		case .print:
			Swift.print(string)
		case .stdout(let flushImmediately):
			let newlined = string + "\n"
			let data = Data(newlined.utf8)
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
				Swift.print(newlined)
			}
		}

	}
}
