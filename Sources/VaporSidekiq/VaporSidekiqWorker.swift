import Foundation
import NIOSidekiq
import NIO
import Service

public protocol VaporSidekiqWorker: NIOSidekiqWorker {
    var container: Container { get }
}

extension VaporSidekiqWorker {
    public func performAsync(_ args: Self.Args) throws -> EventLoopFuture<SidekiqUnitOfWorkValue> {
        return try type(of: self).performAsync(args, queue: queue, retry: retry, on: container)
    }

    public static func performAsync(_ args: Self.Args, queue: SidekiqQueue?, retry: Int?, on container: Container) throws -> EventLoopFuture<SidekiqUnitOfWorkValue> {
        let workValue = SidekiqUnitOfWorkValue(
            worker: self,
            queue: (queue ?? defaultQueue),
            args: try args.toValueArgs(),
            retry: (retry ?? defaultRetry)
        )

        let m = VaporSidekiq(container: container)
        return try m.client.enqueue(workValue: workValue).map(to: SidekiqUnitOfWorkValue.self) {
            return workValue
        }
    }
}
