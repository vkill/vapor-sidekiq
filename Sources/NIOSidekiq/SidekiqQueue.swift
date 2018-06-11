import Foundation

public final class SidekiqQueue {
    public static func `default`() -> SidekiqQueue {
        return SidekiqQueue(name: "default")
    }

    let name: String
    let weight: Int

    public init(name: String, weight: Int = 1) {
        self.name = name
        self.weight = weight
    }
}

extension SidekiqQueue: CustomStringConvertible {
    public var description: String {
        return "{name: \(self.name), weight: \(self.weight)}"
    }
}
