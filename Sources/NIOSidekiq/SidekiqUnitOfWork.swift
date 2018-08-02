import struct Foundation.UUID
import struct Foundation.Date
import struct Foundation.Data
import class Foundation.JSONDecoder
import LiteAny

public typealias SidekiqUnitOfWorkValueArg = LiteAny
public typealias SidekiqUnitOfWorkValueArgs = [SidekiqUnitOfWorkValueArg]

public struct SidekiqUnitOfWorkValue: Codable {
    public static let queueDefault: SidekiqQueue = SidekiqQueue.default()
    public static let retryDefault: Int = 3

    public let workerName: String
    private let queueName: String
    public let args: SidekiqUnitOfWorkValueArgs
    private let retryAny: SidekiqUnitOfWorkValueArg
    public let jid: String
    private let createdAtTS: Double
    private let enqueuedAtTS: Double

    enum CodingKeys: String, CodingKey {
        case workerName = "class"
        case queueName = "queue"
        case args
        case retryAny = "retry"
        case jid
        case createdAtTS = "created_at"
        case enqueuedAtTS = "enqueued_at"
    }

    public var queue: SidekiqQueue {
        if self.queueName.isEmpty {
            return type(of: self).queueDefault
        } else {
            return SidekiqQueue(name: self.queueName)
        }
    }

    public var retry: Int {
        if let retryBoolValue = try? self.retryAny.to(Bool?.self) {
            return retryBoolValue == true ? type(of: self).retryDefault : 0
        } else {
            if let retryIntValue = try? self.retryAny.to(Int.self) {
                return retryIntValue
            } else {
                return type(of: self).retryDefault
            }
        }
    }

    public var createdAt: Date {
        return Date(timeIntervalSince1970: self.createdAtTS)
    }

    public var enqueuedAt: Date {
        return Date(timeIntervalSince1970: self.enqueuedAtTS)
    }

    public init<W:NIOSidekiqWorker>(worker: W.Type, queue: SidekiqQueue, args: SidekiqUnitOfWorkValueArgs, retry: Int) {
        let now = Date()

        self.workerName = String(describing: worker)
        self.queueName = queue.name
        self.args = args
        self.retryAny = SidekiqUnitOfWorkValueArg.int(retry)
        self.jid = UUID().uuidString
        self.createdAtTS = now.timeIntervalSince1970
        self.enqueuedAtTS = now.timeIntervalSince1970
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
        <SidekiqUnitOfWork queue="\(queue)" valueData='\(String(data: valueData, encoding: .utf8) ?? "")'>
        """
    }
}
