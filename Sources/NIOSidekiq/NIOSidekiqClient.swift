import Foundation
import NIO
import Async

public final class NIOSidekiqClient {
    private let m: NIOSidekiq

    public init(m: NIOSidekiq) {
        self.m = m
    }

    public func enqueue(workValue: SidekiqUnitOfWorkValue) throws -> EventLoopFuture<Void> {
        let redis = self.m.redis
        let redisKey = self.m.rediskey

        let queue = workValue.queue

        return try redis.sadd(
            key: redisKey.queues(),
            members: [queue.name]
            ).flatMap(to: Void.self) { saddInt in
                let rawValue = try JSONEncoder().encode(workValue)
                return try redis.lpush(
                    key: redisKey.queue(queue: queue),
                    values: [rawValue]
                ).flatMap(to: Void.self) { lpushInt in
                    return self.m.EventLoopFutureMap(){ () }
            }
        }
    }

}
