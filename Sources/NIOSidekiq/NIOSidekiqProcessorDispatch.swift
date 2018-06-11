import Foundation
import NIO
import Async //TODO

public protocol NIOSidekiqProcessorDispatch {
    func executeJob(workValue: SidekiqUnitOfWorkValue) throws -> EventLoopFuture<Void>
    func executeJob<W:NIOSidekiqWorker>(instance: W, workValue: SidekiqUnitOfWorkValue) throws -> EventLoopFuture<Void>
}

extension NIOSidekiqProcessorDispatch {
    public func executeJob<W:NIOSidekiqWorker>(instance: W, workValue: SidekiqUnitOfWorkValue) throws -> EventLoopFuture<Void> {
        return try instance.perform(type(of: instance).Args(workValue.args))
    }
}

public enum NIOSidekiqProcessorDispatchErrors: Error {
    case UnknowWorkerName
}
