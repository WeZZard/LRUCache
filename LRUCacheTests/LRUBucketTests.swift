//
//  LRUBucketTests.swift
//  LRUCache
//
//  Created on 2019/4/9.
//

import XCTest

@testable
import LRUCache

class LRUBucketTests: XCTestCase {

    func testDeinit_wontCrash() {
        { () -> Void in
            let first: LRUBucket! = LRUBucket<String, Int>()
            var current = first!
            for _ in 0..<100000000 {
                let next = LRUBucket<String, Int>()
                current.next = next
                next.previous = current
                current = next
            }
        }()
    }
}
