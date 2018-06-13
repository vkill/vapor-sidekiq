import Vapor
import Redis
import VaporSidekiq

public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(RedisProvider())

    /// Redis database
    let redisURL = URL(string: Environment.get("REDIS_URL") ?? "redis://:@127.0.0.1:6379")!
    let redisClientConfig = RedisClientConfig(url: redisURL)
    let redisDatabase = try RedisDatabase(config: redisClientConfig)

    /// Register the configured Redis database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: redisDatabase, as: .redis)
    services.register(databases)

    ///
    let serverConfig = NIOServerConfig.default(hostname: "localhost", port: 8080)
    services.register(serverConfig)
}
