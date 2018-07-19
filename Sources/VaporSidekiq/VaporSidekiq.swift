import NIOSidekiq
import Service

public final class VaporSidekiq: NIOSidekiq {
    public static var logger: SidekiqLogger = SidekiqPrintLogger()

    private let container: Container
    public let eventLoop: EventLoop

    public init(container: Container) {
        self.container = container
        self.eventLoop = container.eventLoop
    }

    public func EventLoopFutureMap<T>(_ callback: @escaping () throws -> T) -> EventLoopFuture<T> {
        return Future.map(on: container, callback)
    }

    public lazy var redis: NIOSidekiqRedis = {
        return makeRedis()
    }()

    public func makeRedis() -> NIOSidekiqRedis {
        return VaporSidekiqRedis(container: container)
    }

    public lazy var rediskey: SidekiqRedisKey = {
        return SidekiqRedisKey()
    }()

    public lazy var client: NIOSidekiqClient = {
        return NIOSidekiqClient(redis: redis, redisKey: rediskey)
    }()
}
