import Foundation
#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

public struct SidekiqUtils {
    static func random(_ max: Int) -> UInt32 {
        #if os(Linux)
        return UInt32(Glibc.random()) % UInt32(max + 1)
        #else
        return arc4random_uniform(UInt32(max))
        #endif
    }
}
