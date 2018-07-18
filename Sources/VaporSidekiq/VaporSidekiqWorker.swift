import NIOSidekiq
import Service

public protocol VaporSidekiqWorker: NIOSidekiqWorker {
    var container: Container { get }
}

public enum VaporSidekiqWorkerErrors: Error {
    case enqueueFailed
    case argsArrayEmpty
}

extension VaporSidekiqWorker {
    public func performAsync(_ args: Self.Args) throws -> EventLoopFuture<SidekiqUnitOfWorkValue> {
        return try type(of: self).performAsync(args, queue: queue, retry: retry, on: container)
    }

    public static func performAsync(_ args: Self.Args, queue: SidekiqQueue?, retry: Int?, on container: Container) throws -> EventLoopFuture<SidekiqUnitOfWorkValue> {
        return try self.performAsync([args], queue: queue, retry: retry, on: container).map(to: SidekiqUnitOfWorkValue.self) { workValues in
            guard let workValue = workValues.first else {
                throw VaporSidekiqWorkerErrors.enqueueFailed
            }
            return workValue
        }
    }

    public static func performAsync(_ argsArray: [Self.Args], queue: SidekiqQueue?, retry: Int?, on container: Container) throws -> EventLoopFuture<[SidekiqUnitOfWorkValue]> {
        guard !argsArray.isEmpty else {
            throw VaporSidekiqWorkerErrors.argsArrayEmpty
        }

        var workValues: [SidekiqUnitOfWorkValue] = []
        for args in argsArray {
            let workValue = SidekiqUnitOfWorkValue(
                worker: self,
                queue: (queue ?? queueDefault),
                args: try args.toValueArgs(),
                retry: (retry ?? retryDefault)
            )
            workValues.append(workValue)
        }

        let m = VaporSidekiq(container: container)
        return try m.client.enqueue(workValues: workValues).map(to: [SidekiqUnitOfWorkValue].self) {
            return workValues
        }
    }
}
