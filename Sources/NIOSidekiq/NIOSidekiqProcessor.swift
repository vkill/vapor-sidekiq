import NIO
import NIOConcurrencyHelpers
import Async //TODO

public struct SidekiqProcessorOptions {
    public let queues: [SidekiqQueue]
    public let fetcherType: NIOSidekiqFetcher.Type
    public let dispatch: NIOSidekiqProcessorDispatch

    public init(
        queues: [SidekiqQueue] = [SidekiqQueue.default()],
        fetcherType: NIOSidekiqFetcher.Type = NIOSidekiqReliableFetcher.self,
        dispatch: NIOSidekiqProcessorDispatch
    ) {
        self.queues = queues
        self.fetcherType = fetcherType
        self.dispatch = dispatch
    }
}

public final class NIOSidekiqProcessor {
    private var m: NIOSidekiq

    public let managerIdentity: String
    public let index: Int
    public let identity: String

    public let options: SidekiqProcessorOptions
    private let fetcher: NIOSidekiqFetcher
    private let dispatch: NIOSidekiqProcessorDispatch

    weak var manager: NIOSidekiqManager?

    private let done = Atomic<Bool>(value: false)

    public init(
        m: NIOSidekiq,
        managerIdentity: String,
        index: Int,
        options: SidekiqProcessorOptions
    ) {
        self.m = m

        self.managerIdentity = managerIdentity
        self.index = index
        let identity = "\(managerIdentity):\(index)"
        self.identity = identity

        self.options = options
        self.fetcher = options.fetcherType.init(m: m, queues: options.queues, processorIdentity: identity)
        self.dispatch = options.dispatch
    }

    // TODO
    public func terminate() {
        let _ = self.done.exchange(with: true)
    }

    // TODO
    public func kill() {
        let _ = self.done.exchange(with: true)
    }

    public func start() {
        self.fetcher.processor = self

        self.m.logger.info("\(self) starting.")
        return self.run()
    }

    private func run() {
        self.m.logger.info("\(self) running.")

        guard let manager = self.manager else {
            fatalError("miss manager")
        }

        do {
            try processOne().do { tuple in
                if self.done.load() == false {
                    return self.run()
                } else {
                    manager.processorStopped(processor: self)
                }
            }.catch{ error in
                manager.processorDied(processor: self, reason: "\(error)")
            }
        } catch {
            manager.processorDied(processor: self, reason: "\(error)")
        }
    }

    private func processOne() throws -> EventLoopFuture<Void> {
        return try self.fetcher.retriveWork().flatMap { work in
            if let work = work {
                if self.done.load() == true {
                    return try self.fetcher.requeue(work)
                }

                return try self.process(work)
            } else {
                return self.m.EventLoopFutureMap() { () }
            }
        }
    }

    private func process(_ work: SidekiqUnitOfWork) throws -> EventLoopFuture<Void> {
        guard let workValue = work.value else {
            let reason = "Invalid JSON for work rawValue"
            self.m.logger.error("\(self) process \(work) failed. reason: \(reason).")
            return try self.fetcher.acknowledge(work)
        }

        self.m.logger.info("\(self) processing \(work).")

        return try self.dispatch.executeJob(workValue: workValue).flatMap { _ in
            return try self.fetcher.acknowledge(work)
        }.catchFlatMap{ error in
            let reason = "Run perform failed, error: \(error)"
            self.m.logger.error("\(self) process \(work) failed. reason: \(reason).")
            return try self.fetcher.requeue(work)
        }
    }
}

extension NIOSidekiqProcessor: Equatable {
    public static func == (lhs: NIOSidekiqProcessor, rhs: NIOSidekiqProcessor) -> Bool {
        return lhs.identity == rhs.identity
    }
}

extension NIOSidekiqProcessor: CustomStringConvertible {
    public var description: String {
        return """
        <NIOSidekiqProcessor identity="\(identity)">
        """
    }
}
