import Vapor
import NIOSidekiq
import VaporSidekiq

public func boot(_ app: Application) throws {
    ///
    func runRepeatTimer() throws {
        let _ = app.eventLoop.scheduleTask(in: TimeAmount.seconds(10), runRepeatTimer)
        let _ = try EchoWorker(on: app).performAsync(.init([.string("Hello \(Date())")]))
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
