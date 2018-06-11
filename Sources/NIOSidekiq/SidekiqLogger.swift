import Foundation

public enum SidekiqLoggerLevel: ExpressibleByStringLiteral, CustomStringConvertible {
    case verbose
    case debug
    case info
    case warning
    case error
    case fatal
    case custom(String)

    public init(stringLiteral value: String) {
        self = .custom(value)
    }

    public var description: String {
        switch self {
        case .custom(let s): return s.uppercased()
        case .debug: return "DEBUG"
        case .error: return "ERROR"
        case .fatal: return "FATAL"
        case .info: return "INFO"
        case .verbose: return "VERBOSE"
        case .warning: return "WARNING"
        }
    }
}

public protocol SidekiqLogger: class {
    func log(_ string: String, at level: SidekiqLoggerLevel, file: String, function: String, line: UInt, column: UInt)
}

extension SidekiqLogger {
    public func verbose(_ string: String, file: String = #file, function: String = #function, line: UInt = #line, column: UInt = #column) {
        self.log(string, at: .verbose, file: file, function: function, line: line, column: column)
    }

    public func debug(_ string: String, file: String = #file, function: String = #function, line: UInt = #line, column: UInt = #column) {
        self.log(string, at: .debug, file: file, function: function, line: line, column: column)
    }

    public func info(_ string: String, file: String = #file, function: String = #function, line: UInt = #line, column: UInt = #column) {
        self.log(string, at: .info, file: file, function: function, line: line, column: column)
    }

    public func warning(_ string: String, file: String = #file, function: String = #function, line: UInt = #line, column: UInt = #column) {
        self.log(string, at: .warning, file: file, function: function, line: line, column: column)
    }

    public func error(_ string: String, file: String = #file, function: String = #function, line: UInt = #line, column: UInt = #column) {
        self.log(string, at: .error, file: file, function: function, line: line, column: column)
    }

    public func fatal(_ string: String, file: String = #file, function: String = #function, line: UInt = #line, column: UInt = #column) {
        self.log(string, at: .fatal, file: file, function: function, line: line, column: column)
    }
}

public final class SidekiqPrintLogger: SidekiqLogger {
    public init(){
    }

    public func log(_ string: String, at level: SidekiqLoggerLevel, file: String, function: String, line: UInt, column: UInt) {
        Swift.print("[\(level)] \(string) (\(file):\(function):\(line):\(column))")
    }
}
