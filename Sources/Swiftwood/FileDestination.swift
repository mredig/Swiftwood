import Foundation

/**
`FileDestination`, in contrast with `FilesDestination`, outputs to a single or rotating file. `maxSize` sets the maximum size a log file can exist in bytes
 before rotating to a new log file. if `maxSize` is reached, a new file will be created with a numerical increment from the previous, appending `.1` as the file extension
 if it's the first rotation.
 */
open class FileDestination: SwiftwoodDestination {
	public var format = Swiftwood.Format()
	public var minimumLogLevel: Swiftwood.Level = .veryVerbose
	public var logFilter: LogCategory.Filter = .none
	public var shouldCensor: Bool

	public let maxSize: UInt64

	private var fileHandle: FileHandle
	private let outputFile: URL

	static private func fileHandle(for url: URL, withMaxSize maxSize: UInt64) throws -> FileHandle {
		let latestLogFile = try FileManager
			.default
			.contentsOfDirectory(at: url.deletingLastPathComponent(), includingPropertiesForKeys: [.fileSizeKey])
			.filter { $0.lastPathComponent.contains(url.lastPathComponent) }
			.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
			.last

		let fh: FileHandle
		if let latestLogFile {
			let values = try latestLogFile.resourceValues(forKeys: [.fileSizeKey])

			if UInt64(values.fileSize ?? 0) < maxSize {
				fh = try FileHandle(forUpdating: latestLogFile)
			} else {
				let counterStr = latestLogFile.pathExtension
				let newValue = (Int(counterStr) ?? 0) + 1
				let newURL = url.appendingPathExtension("\(newValue)")

				try Data().write(to: newURL)
				fh = try FileHandle(forUpdating: newURL)
			}
		} else {
			try Data().write(to: url)
			fh = try FileHandle(forUpdating: url)
		}

		if #available(macOS 10.15.4, iOS 13.4, *) {
			try fh.seekToEnd()
		} else {
			fh.seekToEndOfFile()
		}
		return fh
	}

	public init(maxSize: UInt64 = 8_000_000, shouldCensor: Bool, outputFile: URL) throws {
		self.maxSize = maxSize
		self.shouldCensor = shouldCensor

		self.outputFile = outputFile

		try FileManager.default.createDirectory(at: self.outputFile.deletingLastPathComponent(), withIntermediateDirectories: true)

		self.fileHandle = try Self.fileHandle(for: outputFile, withMaxSize: maxSize)
	}

	open func sendToDestination(_ entry: Swiftwood.LogEntry) {
		let formattedMessage = format.convertEntryToString(entry, censoring: shouldCensor)

		let messageData = Data(formattedMessage.utf8) + Data("\n".utf8)
		do {
			try rotateFileIfNeeded()

			if #available(macOS 10.15.4, iOS 13.4, *) {
				try fileHandle.write(contentsOf: messageData)
			} else {
				fileHandle.write(messageData)
			}
		} catch {
			print("Error writing to logging file!: \(error)")
		}
	}

	private func rotateFileIfNeeded() throws {
		let offset: UInt64
		if #available(macOS 10.15.4, iOS 13.4, *) {
			offset = try fileHandle.offset()
		} else {
			offset = fileHandle.offsetInFile
		}

		guard offset >= maxSize else { return }

		let rotatedFile = try Self.fileHandle(for: outputFile, withMaxSize: maxSize)
		fileHandle = rotatedFile
	}
}
