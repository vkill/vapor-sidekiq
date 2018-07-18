import struct Foundation.Data
import NIO

public class SidekiqRedisKey {
    let namespace: String = ""

    public init(){
    }

    public func queues() -> String {
        return "\(self.namespace)queues"
    }

    public func queue(queue: SidekiqQueue) -> String {
        return "\(self.namespace)queue:\(queue.name)"
    }

    public func queueInprogress(queue: SidekiqQueue, identity: String) -> String {
        return "\(self.queue(queue: queue)):inprogress:\(identity)"
    }
}

public protocol NIOSidekiqRedis: AnyObject {
    var m: NIOSidekiq { get }

    func brpoplpush(source: String, destination: String, timeout: Int) throws -> EventLoopFuture<Data?>
    func rpoplpush(source: String, destination: String) throws -> EventLoopFuture<Data?>
    func lrem(key: String, count: Int, value: Data) throws -> EventLoopFuture<Void>
    func lrange(key: String, start: Int, stop: Int) throws -> EventLoopFuture<[Data]>
    func sadd(key: String, members: [String]) throws -> EventLoopFuture<Int>
    func lpush(key: String, values: [Data]) throws -> EventLoopFuture<Int>
}
