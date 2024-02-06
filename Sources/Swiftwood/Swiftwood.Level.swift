import Foundation

extension Swiftwood {
//	if useTerminalColors {
//		// use Terminal colors
//		reset = "\u{001b}[0m"
//		escape = "\u{001b}[38;5;"
//		levelColor.verbose = "251m"     // silver
//		levelColor.debug = "35m"        // green
//		levelColor.info = "38m"         // blue
//		levelColor.warning = "178m"     // yellow
//		levelColor.error = "197m"       // red
//	} else {
//		// use colored Emojis for better visual distinction
//		// of log level for Xcode 8
//		levelColor.verbose = "💜 "     // silver
//		levelColor.debug = "💚 "        // green
//		levelColor.info = "💙 "         // blue
//		levelColor.warning = "💛 "     // yellow
//		levelColor.error = "❤️ "       // red
//	}
	 public struct Level: Comparable, Equatable {
		 public static var veryVerbose = Level(textValue: "🤎 VERY VERBOSE", level: 0)
		 public static var verbose = Level(textValue: "💜 VERBOSE", level: 20)
		 public static var debug = Level(textValue: "💚 DEBUG", level: 40)
		 public static var info = Level(textValue: "💙 INFO", level: 60)
		 public static var warning = Level(textValue: "💛 WARNING", level: 80)
		 public static var error = Level(textValue: "❤️ ERROR", level: 100)
		 public static var critical = Level(textValue: "💔💔 CRITICAL", level: 110)

		 public let textValue: String
		 public let level: Int

		 public init(textValue: String, level: Int) {
			 self.textValue = textValue
			 self.level = level
		 }

		 /// automatically assigns to the closest default log level
		 public init(rawValue: Int) {
			 switch rawValue {
			 case ...19:
				 self.textValue = "🤎 VERY VERBOSE"
			 case 20...39:
				 self.textValue = "💜 VERBOSE"
			 case 40...59:
				 self.textValue = "💚 DEBUG"
			 case 60...79:
				 self.textValue = "💙 INFO"
			 case 80...99:
				 self.textValue = "💛 WARNING"
			 case 100...109:
				 self.textValue = "❤️ ERROR"
			 default: // aka case 110...:
				 self.textValue = "💔💔 CRITICAL"
			 }
			 self.level = rawValue
		 }

		 public static func < (lhs: Swiftwood.Level, rhs: Swiftwood.Level) -> Bool {
			 lhs.level < rhs.level
		 }
	 }
}
