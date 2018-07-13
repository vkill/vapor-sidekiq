import Foundation
import NIO
import NIOConcurrencyHelpers
import Async //TODO

public final class NIOSidekiqReliableFetcher: NIOSidekiqFetcher {
    private let m: NIOSidekiq
    private let queues: [SidekiqQueue]

    weak public var processor: NIOSidekiqProcessor?

    private let nextQueueIndex = Atomic<Int>(value: 0)
    private func nextQueue() -> SidekiqQueue {
        return queues[abs(nextQueueIndex.add(1) % queues.count)]
    }

    public init(m: NIOSidekiq, queues: [SidekiqQueue]) {
        self.m = m
        self.queues = queues
    }

    public func retriveWork() throws -> EventLoopFuture<SidekiqUnitOfWork?> {
        let redis = self.m.redis
        let redisKey = self.m.rediskey

        let queue = nextQueue()

        let key = redisKey.queue(queue: queue)
        let keyInprogress = redisKey.queueInprogress(queue: queue, identity: processor!.identity)

        return try redis.lrange(
            key: keyInprogress,
            start: 0,
            stop: 1
            ).flatMap(to: SidekiqUnitOfWork?.self) { lrangeDataArray in
                if let data = lrangeDataArray.first {
                    return self.m.EventLoopFutureMap() {
                        return try SidekiqUnitOfWork.init(queue: queue, valueData: data)
                    }
                }

                return try redis.rpoplpush(
                    source: key,
                    destination: keyInprogress
                    ).map(to: SidekiqUnitOfWork?.self) { rpoplpushData in
                        if let data = rpoplpushData {
                            return try SidekiqUnitOfWork.init(queue: queue, valueData: data)
                        } else {
                            return nil
                        }
                }
        }
    }

    public func acknowledge(_ work: SidekiqUnitOfWork) throws -> EventLoopFuture<Void> {
        let redis = self.m.redis
        let redisKey = self.m.rediskey

        let queue = work.queue
        let value = work.valueData

        return try redis.lrem(
            key: redisKey.queueInprogress(queue: queue, identity: self.processor!.identity),
            count: -1,
            value: value
        )
    }

    public func requeue(_ work: SidekiqUnitOfWork) throws -> EventLoopFuture<Void> {
        // nothing to do

        return self.m.EventLoopFutureMap(){ () }
    }
}
