import Foundation

extension Swiftwood {
	public struct LogEntry {
		public let timestamp: Date
		public let logLevel: Level
		public let message: MessageComponents
		public let category: LogCategory
		public let file: String
		public let function: String
		public let lineNumber: Int
		public let buildInfo: String?
		public let context: Any?
	}
}
