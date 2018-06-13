import Foundation
import NIO
import Async //TODO

public enum NIOSidekiqClientEnqueueErrors: Error {
    case manyQueue
    case missingQueue
}

public final class NIOSidekiqClient {
    private let m: NIOSidekiq

    public init(m: NIOSidekiq) {
        self.m = m
    }

    public func enqueue(workValue: SidekiqUnitOfWorkValue) throws -> EventLoopFuture<Void> {
        return try self.enqueue(workValues: [workValue])
    }

    public func enqueue(workValues: [SidekiqUnitOfWorkValue]) throws -> EventLoopFuture<Void> {
        let redis = self.m.redis
        let redisKey = self.m.rediskey

        let queueSet = Set<SidekiqQueue>(workValues.map{ $0.queue })
        guard queueSet.count == 1 else {
            throw NIOSidekiqClientEnqueueErrors.manyQueue
        }

        guard let queue = queueSet.first else {
            throw NIOSidekiqClientEnqueueErrors.missingQueue
        }

        return try redis.sadd(
            key: redisKey.queues(),
            members: [queue.name]
        ).flatMap(to: Void.self) { saddInt in
            let values = workValues.map { try! JSONEncoder().encode($0) }
            return try redis.lpush(
                key: redisKey.queue(queue: queue),
                values: values
                ).flatMap(to: Void.self) { lpushInt in
                    return self.m.EventLoopFutureMap(){ () }
            }
        }
    }

}
