import Foundation
import NIOSidekiq
import NIO
import Redis

public final class VaporSidekiqRedis: NIOSidekiqRedis {
    public let m: NIOSidekiq
    private let container: Container

    public init(m: NIOSidekiq, container: Container) {
        self.m = m
        self.container = container
    }

    //
    public func rpoplpush(source: String, destination: String) throws -> Future<Data?> {
        return container.withPooledConnection(to: .redis) { client in
            return client.rpoplpush(source: source, destination: destination).map(to: Data?.self) { redisData in
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
            return client.lrange(list: key, range: start...stop).map(to: [Data].self) { redisData in
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
}

extension RedisClient {
    public func lrem(_ item: RedisData, count: Int, in list: String) -> Future<Void> {
        let resp = command("LREM", [RedisData(bulk: list), RedisData(bulk: count.description), item])
        return resp.transform(to: ())
    }

    public func sadd(_ members: [RedisData], to set: String) -> Future<Int> {
        var args: [RedisData] = members
        args.insert(RedisData(stringLiteral: set), at: 0)
        return command("SADD", args).map { data in
            guard let value = data.int else {
                throw RedisError(identifier: "sadd", reason: "Could not convert resp to int", source: .capture())
            }
            return value
        }
    }
}

