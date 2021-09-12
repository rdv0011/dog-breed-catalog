//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation

let log = Logger()

enum CategoryLogLevel: Int {
    case verbose
    case warning
    case debug
    case error
}

extension CategoryLogLevel: CustomStringConvertible {
    var description: String {
        switch self {
        case .verbose:
            return "⚪️"
        case .warning:
            return "⚠️"
        case .debug:
            return "🔵"
        case .error:
            return "⛔️"
        }
    }
}

final class LogCategory {
    let category: String
    let defaultLogLevel: CategoryLogLevel

    static let uncategorized = LogCategory(category: "uncategorized",
                                           defaultLogLevel: .debug)

    init(category: String, defaultLogLevel: CategoryLogLevel = .warning) {
        self.category = category
        self.defaultLogLevel = defaultLogLevel
    }

    func canLog(for level: CategoryLogLevel,
                logLevels: [LogCategory: CategoryLogLevel]) -> Bool {
        // For non debug build print errors only
#if !DEBUG
        level == .error
#else
        (logLevels[self] ?? defaultLogLevel).rawValue <= level.rawValue
#endif
    }
}

extension LogCategory: CustomStringConvertible {
    var description: String {
        category
    }
}

extension LogCategory: Hashable {
    static func == (lhs: LogCategory, rhs: LogCategory) -> Bool {
        return lhs.category == rhs.category
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.category)
    }
}

/// Implements logging capability
final class Logger {
    var logLevels = [LogCategory: CategoryLogLevel]()
    public func verbose(_ category: LogCategory,
                      _ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        guard category.canLog(for: .verbose, logLevels: logLevels) else { return }

        log(message(),
            level: .verbose,
            category: category,
            file: file,
            function: function,
            line: line)
    }

    public func verbose(_ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        verbose(.uncategorized,
                message(),
                file: file,
                function: function,
                line: line)
    }

    public func warning(_ category: LogCategory,
                      _ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        guard category.canLog(for: .warning, logLevels: logLevels) else { return }

        log(message(),
            level: .warning,
            category: category,
            file: file,
            function: function,
            line: line)
    }

    public func warning(_ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        warning(.uncategorized, message(),
                file: file,
                function: function,
                line: line)
    }

    public func debug(_ category: LogCategory,
                      _ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        guard category.canLog(for: .debug, logLevels: logLevels) else { return }

        log(message(),
            level: .debug,
            category: category,
            file: file,
            function: function,
            line: line)
    }

    public func debug(_ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        debug(.uncategorized,
              message(),
              file: file,
              function: function,
              line: line)
    }

    public func error(_ category: LogCategory,
                      _ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        guard category.canLog(for: .error, logLevels: logLevels) else { return }

        log(message(),
            level: .error,
            category: category,
            file: file,
            function: function,
            line: line)
    }

    public func error(_ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        error(.uncategorized,
              message(),
              file: file,
              function: function,
              line: line)
    }

    private func log(_ message: String,
                     level: CategoryLogLevel,
                     category: LogCategory,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        print("\(level)[\(category)][\((file as NSString).lastPathComponent) \(function):\(line)] \(message)")
    }
}
