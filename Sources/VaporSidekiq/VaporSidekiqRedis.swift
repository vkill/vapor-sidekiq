import NIOSidekiq
import Redis

public final class VaporSidekiqRedis: NIOSidekiqRedis {
    private let container: Container

    public init(container: Container) {
        self.container = container
    }

    //
    public func brpoplpush(source: String, destination: String, timeout: Int = 0) throws -> Future<Data?> {
        return fetchFutureClient().flatMap { client in
            if client.isClosed {
                let _ = self.makeFutureClient()
                return try self.brpoplpush(source: source, destination: destination, timeout: timeout)
            }
            return client.brpoplpush(source: source, destination: destination, timeout: timeout).map { redisData in
                return redisData.data
            }
        }
    }

    public func rpoplpush(source: String, destination: String) throws -> Future<Data?> {
        return container.withPooledConnection(to: .redis) { client in
            return client.rpoplpush(source: source, destination: destination).map { redisData in
                return redisData.data
            }
        }
    }

    public func lrem(key: String, count: Int, value: Data) throws -> Future<Void> {
        return container.withPooledConnection(to: .redis) { client in
            return client.lrem(RedisData.bulkString(value), count: count, in: key)
        }
    }

    public func lrange(key: String, start: Int, stop: Int) throws -> Future<[Data]> {
        return container.withPooledConnection(to: .redis) { client in
            return client.lrange(list: key, range: start...stop).map { redisData in
                if let array = redisData.array {
                    return array.compactMap{ $0.data }
                } else {
                    return []
                }
            }
        }
    }

    public func sadd(key: String, members: [String]) throws -> Future<Int> {
        return container.withPooledConnection(to: .redis) { client in
            return client.sadd(members.map{ RedisData.bulkString($0) }, to: key)
        }
    }

    public func lpush(key: String, values: [Data]) throws -> Future<Int> {
        return container.withPooledConnection(to: .redis) { client in
            return client.lpush(values.map{ RedisData.bulkString($0) }, into: key)
        }
    }


    //
    private var futureClient: Future<RedisClient>?

    private func fetchFutureClient() -> Future<RedisClient> {
        if let futureClient = self.futureClient {
            return futureClient
        }
        return makeFutureClient()
    }

    private func makeFutureClient() -> Future<RedisClient> {
        let futureClient = self.container.newConnection(to: .redis)
        self.futureClient = futureClient
        return futureClient
    }
}

extension RedisClient {
    public func brpoplpush(source: String, destination: String, timeout: Int) -> Future<RedisData> {
        return command("BRPOPLPUSH", [RedisData(bulk: source), RedisData(bulk: destination), RedisData(bulk: String(timeout))])
    }

    public func lrem(_ item: RedisData, count: Int, in list: String) -> Future<Void> {
        let resp = command("LREM", [RedisData(bulk: list), RedisData(bulk: count.description), item])
        return resp.transform(to: ())
    }

    public func sadd(_ members: [RedisData], to set: String) -> Future<Int> {
        var args: [RedisData] = members
        args.insert(RedisData(bulk: set), at: 0)
        return command("SADD", args).map { data in
            guard let value = data.int else {
                throw RedisError(identifier: "sadd", reason: "Could not convert resp to int")
            }
            return value
        }
    }
}

