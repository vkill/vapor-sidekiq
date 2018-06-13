import XCTest
@testable import VaporSidekiq

final class VaporSidekiqTests: XCTestCase {
    func testRedis() throws {
        let sidekiq = VaporSidekiq(container: Helper.makeApp())
        XCTAssert(sidekiq.redis is VaporSidekiqRedis)
    }

    static var allTests = [
        ("testRedis", testRedis)
    ]
}
