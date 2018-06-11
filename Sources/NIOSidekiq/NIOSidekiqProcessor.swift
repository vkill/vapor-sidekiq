import Foundation
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
    public let index: Int
    public let options: SidekiqProcessorOptions
    private let fetcher: NIOSidekiqFetcher
    private let dispatch: NIOSidekiqProcessorDispatch

    weak var manager: NIOSidekiqManager?

    public lazy var identity: String = {
        return "\(self.manager!.identity):\(index)"
    }()

    private let done = Atomic<Bool>(value: false)

    public init(
        m: NIOSidekiq,
        index: Int,
        options: SidekiqProcessorOptions
    ) {
        self.m = m
        self.index = index
        self.options = options
        self.fetcher = options.fetcherType.init(m: m, queues: options.queues)
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
        let _ = self.m.eventLoop.scheduleTask(in: TimeAmount.seconds(0), run)
    }

    private func run() throws {
        self.m.logger.info("\(self) running.")
        try processOne().do { tuple in
            if self.done.load() == false {
                let _ = self.m.eventLoop.scheduleTask(in: TimeAmount.seconds(5), self.run)
            } else {
                self.manager?.processorStopped(processor: self)
            }
        }.catch{ error in
            self.manager?.processorDied(processor: self, reason: error.localizedDescription)
        }
    }

    private func processOne() throws -> EventLoopFuture<Void> {
        return try self.fetcher.retriveWork().flatMap(to: Void.self) { work in
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

        return try self.dispatch.executeJob(workValue: workValue).flatMap(to: Void.self) { _ in
            return try self.fetcher.acknowledge(work)
        }.catchFlatMap{ error in
            let reason = "Run perform error \(error.localizedDescription)"
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
