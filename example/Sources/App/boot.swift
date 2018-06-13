import Vapor
import NIOSidekiq
import VaporSidekiq

public func boot(_ app: Application) throws {
    ///
    func runRepeatTimer() throws {
        let _ = app.eventLoop.scheduleTask(in: TimeAmount.seconds(12), runRepeatTimer)
        let _ = try EchoWorker(on: app).performAsync(.init([.string("Time: \(Date())")]))
    }
    try runRepeatTimer()

    ///
    VaporSidekiq.logger = SidekiqVaporLogger(try app.make(Logger.self))

    let sidekiq = VaporSidekiq(container: app)
    let sidekiqProcessorOptions = SidekiqProcessorOptions(
        dispatch: MyNIOSidekiqProcessorDispatch(on: app)
    )
    let sidekiqManager = NIOSidekiqManager(
        m: sidekiq,
        concurrency: 1,
        processorOptions: sidekiqProcessorOptions
    )
    sidekiqManager.start()
}

public class MyNIOSidekiqProcessorDispatch: NIOSidekiqProcessorDispatch {
    let container: Container

    public init(on container: Container) {
        self.container = container
    }

    public func executeJob(workValue: SidekiqUnitOfWorkValue) throws -> EventLoopFuture<Void> {
        switch workValue.workerName {
        case "EchoWorker":
            return try self.executeJob(instance: EchoWorker(on: container), workValue: workValue)
        default:
            throw NIOSidekiqProcessorDispatchErrors.UnknowWorkerName
        }
    }
}
