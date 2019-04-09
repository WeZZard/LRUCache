//
//  _BucketTests.swift
//  LRUCache
//
//  Created on 2019/4/9.
//

import XCTest

@testable
import LRUCache

class _BucketTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
	
    func testDeinit_wontCrash() {
        autoreleasepool {
            let first: _Bucket! = _Bucket<String, Int>()
            var current = first!
            for _ in 0..<1000000 {
                let next = _Bucket<String, Int>()
                current.next = next
                next.previous = current
                current = next
            }
        }
    }
}
