import Service

public final class Application: Container {
    public let config: Config
    public var environment: Environment
    public let services: Services

    public let serviceCache: ServiceCache

    private var eventLoopGroup: EventLoopGroup
    public var eventLoop: EventLoop {
        return eventLoopGroup.next()
    }

    public init(config: Config, environment: Environment, services: Services) {
        self.config = config
        self.environment = environment
        self.services = services

        self.serviceCache = .init()

        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }
}

final class Helper {
    static func makeApp() -> Application {
        var config = Config()
        var env = Environment.testing
        var services = Services()

        return Application(
            config: config,
            environment: env,
            services: services
        )
    }
}
