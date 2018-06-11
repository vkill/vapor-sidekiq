import XCTest

import VaporSidekiqTests

var tests = [XCTestCaseEntry]()
tests += VaporSidekiqTests.allTests()
tests += NIOSidekiqTests.allTests()
XCTMain(tests)