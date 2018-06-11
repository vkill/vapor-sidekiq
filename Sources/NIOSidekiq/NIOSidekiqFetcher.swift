import Foundation
import NIO

public protocol NIOSidekiqFetcher: AnyObject {
    var processor: NIOSidekiqProcessor? {set get}

    init(m: NIOSidekiq, queues: [SidekiqQueue])

    func retriveWork() throws -> EventLoopFuture<SidekiqUnitOfWork?>
    func acknowledge(_ work: SidekiqUnitOfWork) throws -> EventLoopFuture<Void>
    func requeue(_ work: SidekiqUnitOfWork) throws -> EventLoopFuture<Void>
}
