import Foundation

extension Swiftwood {
	public struct Format {
		public static var defaultDateFormatter: DateFormatter = {
			let formatter = DateFormatter()
			formatter.dateFormat = "MM/dd/yyyy HH:mm:ss.SSS"
			return formatter
		}()

		public var parts: [Part]
		public var separator: String
		public var contextFormatter: ContextFormatter = .convertToString

		public static let defaultFormattingParts: [Part] = [
			.timestamp(),
			.staticText(" ("),
			.logLevel,
			.staticText(" "),
			.category,
			.staticText(") "),
			.file,
			.staticText(" "),
			.function,
			.staticText(":"),
			.lineNumber,
			.staticText(" - "),
			.message,
		]

		public init(
			parts: [Part] = Self.defaultFormattingParts,
			separator: String = ""
		) {
			self.parts = parts
			self.separator = separator
		}

		public func convertEntryToString(_ entry: LogEntry, censoring: Bool) -> String {
			var output: [String] = []

			for part in parts {
				switch part {
				case .timestamp(let formatter):
					output.append(formatter.string(from: entry.timestamp))
				case .logLevel:
					output.append(entry.logLevel.textValue)
				case .staticText(let string):
					output.append(string)
				case .message:
					let message = entry
						.message
						.map {
							if
								censoring,
								let censored = $0 as? CensoredLogItem {

								return censored.censoredDescription
							} else {
								return String(describing: $0)
							}
						}
						.joined(separator: " ")
					output.append(message)
				case .category:
					output.append(entry.category.rawValue)
				case .file:
					let url = URL(fileURLWithPath: entry.file)
					let file = url.lastPathComponent
					output.append(file)
				case .function:
					output.append(entry.function)
				case .lineNumber:
					output.append("\(entry.lineNumber)")
				case .buildInfo:
					output.append(entry.buildInfo ?? "nil")
				case .context:
					output.append(contextFormatter.formatContext(entry.context))
				}
			}

			return output.joined(separator: separator)
		}

		public enum Part {
			case timestamp(format: DateFormatter = Format.defaultDateFormatter)
			case logLevel
			case staticText(String)
			case message
			case category
			case file
			case function
			case lineNumber
			case buildInfo
			case context
		}

		public enum ContextFormatter {
			/// Just does `"\(context)"`
			case convertToString

			/// Attempts to cast the context as `[String: Any]` and output in a structured format.
			case attemptDictionaryCast

			/// Allows providing a custom format strategy to output the context
			case custom((Any?) -> String)

			public func formatContext(_ context: Any?) -> String {
				method(context)
			}

			private var method: (Any?) -> String {
				switch self {
				case .convertToString:
					return {
						guard let exists = $0 else { return "" }
						return "Context: \(exists)"
					}
				case .attemptDictionaryCast:
					return {
						guard
							let dictionary = $0 as? [String: Any]
						else { return Self.convertToString.method($0) }

						let sorted = dictionary.sorted(by: { $0.key < $1.key })
						var output = "Context:\n"
						for (key, value) in sorted {
							output += "\t\(key): \(value)\n"
						}
						return output
					}

				case .custom(let custom):
					return custom
				}
			}
		}
	}
}
