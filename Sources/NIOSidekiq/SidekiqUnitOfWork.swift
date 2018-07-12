import Foundation
import LiteAny

public typealias SidekiqUnitOfWorkValueArg = LiteAny
public typealias SidekiqUnitOfWorkValueArgs = [SidekiqUnitOfWorkValueArg]

public struct SidekiqUnitOfWorkValue: Codable {
    public static let queueDefault = SidekiqQueue.default()
    public static let retryDefault = 3

    public let workerName: String
    public let queueName: String
    public let args: SidekiqUnitOfWorkValueArgs
    public let _retry: SidekiqUnitOfWorkValueArg
    public let jid: String
    public let created_at: Double
    public let enqueued_at: Double

    enum CodingKeys: String, CodingKey {
        case workerName = "class"
        case queueName = "queue"
        case args
        case _retry = "retry"
        case jid
        case created_at
        case enqueued_at
    }

    public var queue: SidekiqQueue {
        if self.queueName.isEmpty {
            return type(of: self).queueDefault
        } else {
            return SidekiqQueue(name: self.queueName)
        }
    }

    public var retry: Int {
        if let retryBoolValue = try? self._retry.to(Bool?.self) {
            return retryBoolValue == true ? type(of: self).retryDefault : 0
        } else {
            return try! self._retry.to(Int.self)
        }
    }

    public init<W:NIOSidekiqWorker>(worker: W.Type, queue: SidekiqQueue, args: SidekiqUnitOfWorkValueArgs, retry: Int) {
        self.workerName = String(describing: worker)
        self.queueName = queue.name
        self.args = args
        self._retry = SidekiqUnitOfWorkValueArg.int(retry)
        self.jid = UUID().uuidString
        self.created_at = Date().timeIntervalSince1970
        self.enqueued_at = Date().timeIntervalSince1970
    }
}

extension SidekiqUnitOfWorkValue: CustomStringConvertible {
    public var description: String {
        return """
        <SidekiqUnitOfWorkValue jid="\(jid)" workerName="\(workerName)" queueName="\(queueName)" args="\(args)" retry=\(retry)>
        """
    }
}

public class SidekiqUnitOfWork {
    public let queue: SidekiqQueue
    public let valueData: Data

    public required init(queue: SidekiqQueue, valueData: Data) throws {
        self.queue = queue
        self.valueData = valueData
    }

    lazy var value: SidekiqUnitOfWorkValue? = {
        return try? JSONDecoder().decode(SidekiqUnitOfWorkValue.self, from: valueData)
    }()
}

extension SidekiqUnitOfWork: CustomStringConvertible {
    public var description: String {
        return """
        <SidekiqUnitOfWork queue="\(queue)" valueData='\(String(data: valueData, encoding: .utf8)!)'>
        """
    }
}
