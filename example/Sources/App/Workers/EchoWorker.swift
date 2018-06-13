import Vapor
import NIOSidekiq
import VaporSidekiq

final class EchoWorker: AppWorker, VaporSidekiqWorker {
    var queue: SidekiqQueue? = nil
    var retry: Int? = nil

    public struct Args: SidekiqWorkerPerformArgs {
        let message: String

        public init(_ valueArgs: SidekiqUnitOfWorkValueArgs) throws {
            self.message = try valueArgs[0].to(String.self)
        }
        public func toValueArgs() throws -> SidekiqUnitOfWorkValueArgs {
            return [.string(message)]
        }
    }

    func perform(_ args: Args) throws -> Future<Void> {
        return Future.map(on: self.container){ print("\(args.message)") }
    }
}
