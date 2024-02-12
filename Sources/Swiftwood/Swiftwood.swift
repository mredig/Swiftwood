import Foundation

// log dumping
public class Swiftwood {
	public static let logFileURLs: [URL] = []

	#if DEBUG
	static var testingVerbosity = false
	#endif
	private static var _cachedBuildInfo: String??
	private static var _buildInfoGenerator: () -> String? = {
		Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
	}
	/**
	 If `cacheBuildInfo` set to `true` (which is the default), will only run if the value is not already cached.
	 */
	public static var buildInfoGenerator: () -> String? {
		get { _buildInfoGenerator }
		set {
			_buildInfoGenerator = newValue
			_cachedBuildInfo = nil
		}
	}
	public static var cacheBuildInfo = true

	public private(set) static var destinations: [SwiftwoodDestination] = []

	public static var logFormat = Format()

	public enum ReplicationOption {
		/// Replaces all destinations of the same type
		case replaceAlike
		/// Doesn't append new destination if another of the same type already exists
		case forfeitToAlike
		/// Doesn't evaluate if any similar destination already exists, it just adds it
		case appendAlike
	}
	/**
	 Appends destination to `Self.destinations` array. `replicationOption` defaults to `.forfeitToAlike`
	 */
	public static func appendDestination(_ destination: SwiftwoodDestination, replicationOption: ReplicationOption = .forfeitToAlike) {

		switch replicationOption {
		case .forfeitToAlike:
			guard destinations.allSatisfy({ type(of: $0) != type(of: destination) }) else { return }
			destinations.append(destination)
		case .appendAlike:
			destinations.append(destination)
		case .replaceAlike:
			while let index = destinations.firstIndex(where: { type(of: destination) == type(of: $0) }) {
				destinations.remove(at: index)
			}
			destinations.append(destination)
		}
	}

	/**
	 Removes `destination` from `Self.destinations`
	 */
	public static func removeDestination(_ destination: SwiftwoodDestination) {
		destinations.removeAll(where: { $0 === destination })
	}

	public static func clearDestinations() {
		destinations.removeAll()
	}

	public static func info(
		_ message: Any ...,
		category: LogCategory = .default,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil) {
			custom(level: .info, message, category: category, file: file, function: function, line: line, context: context)
		}

	public static func warning(
		_ message: Any ...,
		category: LogCategory = .default,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil) {
			custom(level: .warning, message, category: category, file: file, function: function, line: line, context: context)
		}

	public static func error(
		_ message: Any ...,
		category: LogCategory = .default,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil) {
			custom(level: .error, message, category: category, file: file, function: function, line: line, context: context)
		}

	public static func critical(
		_ message: Any ...,
		category: LogCategory = .default,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil) {
			custom(level: .critical, message, category: category, file: file, function: function, line: line, context: context)
		}

	public static func debug(
		_ message: Any ...,
		category: LogCategory = .default,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil) {
			custom(level: .debug, message, category: category, file: file, function: function, line: line, context: context)
		}

	public static func verbose(
		_ message: Any ...,
		category: LogCategory = .default,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil) {
			custom(level: .verbose, message, category: category, file: file, function: function, line: line, context: context)
		}


	public static func veryVerbose(
		_ message: Any ...,
		category: LogCategory = .default,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil) {
			custom(level: .veryVerbose, message, category: category, file: file, function: function, line: line, context: context)
		}

	public static func custom(
		level: Level,
		_ message: Any ...,
		category: LogCategory = .default,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil) {
			let components = MessageComponents(rawValue: message)

			customv(
				level: level,
				components,
				category: category,
				file: file,
				function: function,
				line: line,
				context: context)
		}

	public struct MessageComponents: RawRepresentable {
		public let rawValue: [Any]

		public init(rawValue: [Any]) {
			self.rawValue = rawValue
		}
	}

	public static func customv(
		level: Level,
		_ message: MessageComponents,
		category: LogCategory = .default,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil) {
			let date = Date()
			let logEntry = LogEntry(
				timestamp: date,
				logLevel: level,
				message: message,
				category: category,
				file: file,
				function: function,
				lineNumber: line,
				buildInfo: getBuildInfo(),
				context: context)

			destinations.forEach {
				$0.sendToDestinationIfPassesFilters(logEntry)
			}
		}

	private static func getBuildInfo() -> String? {
		if cacheBuildInfo, let _cachedBuildInfo {
			#if DEBUG
			if testingVerbosity { print("cache hit") }
			#endif
			return _cachedBuildInfo
		} else {
			let cachedBuildInfo = buildInfoGenerator()
			_cachedBuildInfo = cachedBuildInfo
			return cachedBuildInfo
		}
	}

	public static func clearLogs() {}
}
