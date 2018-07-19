import struct Foundation.Data
import class Foundation.JSONEncoder
import NIO
import Async //TODO

public enum NIOSidekiqClientEnqueueErrors: Error {
    case manyQueue
    case missingQueue
}

public final class NIOSidekiqClient {
    private let redis: NIOSidekiqRedis
    private let redisKey: SidekiqRedisKey

    public init(redis: NIOSidekiqRedis, redisKey: SidekiqRedisKey) {
        self.redis = redis
        self.redisKey = redisKey
    }

    public func enqueue(workValue: SidekiqUnitOfWorkValue) throws -> EventLoopFuture<Void> {
        return try self.enqueue(workValues: [workValue])
    }

    public func enqueue(workValues: [SidekiqUnitOfWorkValue]) throws -> EventLoopFuture<Void> {
        let queueSet = Set<SidekiqQueue>(workValues.map{ $0.queue })
        guard queueSet.count == 1 else {
            throw NIOSidekiqClientEnqueueErrors.manyQueue
        }

        guard let queue = queueSet.first else {
            throw NIOSidekiqClientEnqueueErrors.missingQueue
        }

        return try self.redis.sadd(
            key: self.redisKey.queues(),
            members: [queue.name]
        ).flatMap(to: Void.self) { saddInt in
            var values: [Data] = []
            for workValue in workValues {
                values.append(try JSONEncoder().encode(workValue))
            }
            return try self.redis.lpush(
                key: self.redisKey.queue(queue: queue),
                values: values
            ).transform(to: ())
        }
    }

}
