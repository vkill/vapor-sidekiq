import NIO

public protocol NIOSidekiqWorker: AnyObject {
    var queue: SidekiqQueue? { get }
    var retry: Int? { get }

    associatedtype Args: SidekiqWorkerPerformArgs
    func perform(_ args: Args) throws -> EventLoopFuture<Void>
}

extension NIOSidekiqWorker {
    public static var queueDefault: SidekiqQueue {
        return SidekiqUnitOfWorkValue.queueDefault
    }
    public static var retryDefault: Int {
        return SidekiqUnitOfWorkValue.retryDefault
    }
}
