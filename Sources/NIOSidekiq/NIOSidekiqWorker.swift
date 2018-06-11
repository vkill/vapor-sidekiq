import Foundation
import NIO

public protocol NIOSidekiqWorker: AnyObject {
    var queue: SidekiqQueue? { get }
    var retry: Int? { get }

    associatedtype Args: SidekiqWorkerPerformArgs
    func perform(_ args: Args) throws -> EventLoopFuture<Void>
}

extension NIOSidekiqWorker {
    public static var defaultQueue: SidekiqQueue {
        return SidekiqQueue.default()
    }
    public static var defaultRetry: Int {
        return 3
    }
}
