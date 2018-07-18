import NIO

public protocol NIOSidekiq: AnyObject {
    static var logger: SidekiqLogger { get }

    var eventLoop: EventLoop { get }

    var redis: NIOSidekiqRedis { get }
    var rediskey: SidekiqRedisKey { get }

    var client: NIOSidekiqClient { get }

    func makeRedis() -> NIOSidekiqRedis
    func EventLoopFutureMap<T>(_ callback: @escaping () throws -> T) -> EventLoopFuture<T>
}

extension NIOSidekiq {
    public var logger: SidekiqLogger {
        return type(of: self).logger
    }
}
