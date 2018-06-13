import Vapor
import NIOSidekiq

///
import Logging
extension SidekiqLoggerLevel {
    var vaporLoggingLogLevel: LogLevel {
        return LogLevel.custom(self.description)
    }
}
public final class SidekiqVaporLogger: SidekiqLogger {
    let vaporLogger: Logger
    init(_ vaporLogger: Logger) {
        self.vaporLogger = vaporLogger
    }

    public func log(_ string: String, at level: SidekiqLoggerLevel, file: String, function: String, line: UInt, column: UInt) {
        self.vaporLogger.log(string, at: level.vaporLoggingLogLevel, file: file, function: function, line: line, column: column)
    }
}

/*
///
import SwiftyBeaverProvider
public final class SidekiqSwiftyBeaverLogger: SidekiqLogger {
    let swiftyBeaverLogger: SwiftyBeaverLogger
    init(_ swiftyBeaverLogger: SwiftyBeaverLogger) {
        self.swiftyBeaverLogger = swiftyBeaverLogger
    }

    public func log(_ string: String, at level: SidekiqLoggerLevel, file: String, function: String, line: UInt, column: UInt) {
        self.swiftyBeaverLogger.log(string, at: level.vaporLoggingLogLevel, file: file, function: function, line: line, column: column)
    }
}

*/
