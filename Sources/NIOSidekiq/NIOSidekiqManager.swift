import NIO
import NIOConcurrencyHelpers

public final class NIOSidekiqManager {

    private var m: NIOSidekiq
    private let concurrency: Int

    private let index: Int
    private static let nextIndex = Atomic<Int>(value: 1)
    public let identity: String

    private(set) var processors: [NIOSidekiqProcessor]
    private let done = Atomic<Bool>(value: false)

    public init(
        m: NIOSidekiq,
        concurrency: Int = 1,
        processorOptions: SidekiqProcessorOptions
    ) {
        self.m = m
        self.concurrency = concurrency

        let managerIndex = type(of: self).nextIndex.add(1)
        self.index = managerIndex
        let identity = String(managerIndex)
        self.identity = identity

        self.processors = (1...concurrency).map { processorIndex in
            return NIOSidekiqProcessor(
                m: m,
                managerIdentity: identity,
                index: processorIndex,
                options: processorOptions
            )
        }
    }

    public func start() {
        self.m.logger.info("SidekiqManager \(self) starting \(concurrency) processors.")
        processors.forEach { processor in
            processor.manager = self
            processor.start()
        }
    }

    func processorStopped(processor: NIOSidekiqProcessor) {
        self.m.logger.error("\(processor) stopped.")

        if let index = self.processors.index(of: processor) {
            self.processors.remove(at: index)
        }
    }

    func processorDied(processor: NIOSidekiqProcessor, reason: String) {
        self.m.logger.error("\(processor) died. reason: \(reason)")

        if let index = self.processors.index(of: processor) {
            self.processors.remove(at: index)
        }
        if done.load() == false {
            let processor = NIOSidekiqProcessor(
                m: self.m,
                managerIdentity: self.identity,
                index: processor.index,
                options: processor.options
            )
            processor.manager = self
            self.processors.append(processor)
            processor.start()
        }
    }
}

extension NIOSidekiqManager: CustomStringConvertible {
    public var description: String {
        return """
        <NIOSidekiqManager identity="\(identity)">
        """
    }
}
