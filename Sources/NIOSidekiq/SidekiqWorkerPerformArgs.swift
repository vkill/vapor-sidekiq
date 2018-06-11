import Foundation

enum SidekiqWorkerPerformArgsErrors: Error {
    case Invalid
}

public protocol SidekiqWorkerPerformArgs: Codable {
    init(_ valueArgs: SidekiqUnitOfWorkValueArgs) throws
    func toValueArgs() throws -> SidekiqUnitOfWorkValueArgs
}
