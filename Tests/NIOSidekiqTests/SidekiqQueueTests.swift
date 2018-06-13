import XCTest
@testable import NIOSidekiq

final class SidekiqQueueTests: XCTestCase {
    func testHashable() throws {
        let name = "default"
        let queue = SidekiqQueue(name: name)
        XCTAssert(queue.hashValue == name.hashValue)
    }

    static var allTests = [
        ("testHashable", testHashable)
    ]
}
