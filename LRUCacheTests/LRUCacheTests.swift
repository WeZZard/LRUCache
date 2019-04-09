//
//  LRUCacheTests.swift
//  LRUCache
//
//  Created on 2019/4/9.
//

import XCTest

@testable
import LRUCache

class LRUCacheTests: XCTestCase {
    var cache: LRUCache<String, Int>!
    
    override func setUp() {
        super.setUp()
        cache = LRUCache()
    }
    
    override func tearDown() {
        super.tearDown()
        cache = nil
    }
	
    // MARK: Insert Value for Key
    func testInsertValueForKey_insertsValueForKey() {
        let cache = LRUCache<String, Int>()
        
        cache.insertValue(0, forKey: "zero")
        XCTAssertEqual(cache.value(forKey: "zero"), 0)
    }
    
    func testInsertValueForKey_insertsBucket() {
        let cache = LRUCache<String, Int>()
        
        XCTAssertTrue(cache._bucketsForKeys.isEmpty)
        
        cache.insertValue(0, forKey: "zero")
        
        XCTAssertFalse(cache._bucketsForKeys.isEmpty)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
    }
    
    func testInsertValueForKey_insertsBucketRightAfterHead() {
        let cache = LRUCache<String, Int>()
        
        cache.insertValue(0, forKey: "zero")
        
        XCTAssertFalse(cache._bucketsForKeys.isEmpty)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next)
        
        cache.insertValue(1, forKey: "one")
        
        XCTAssertFalse(cache._bucketsForKeys.isEmpty)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous!.previous)
    }
    
    func testInsertValueForKey_evictsKeyValuePairs_whenStoredKeyValuePairsCountIsGoingToBeLargerThanMaxCount() {
        let cache = LRUCache<String, Int>(maxCount: 1)
        
        cache.insertValue(0, forKey: "zero")
        
        XCTAssertFalse(cache._bucketsForKeys.isEmpty)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next)
        
        cache.insertValue(1, forKey: "one")
        
        XCTAssertFalse(cache._bucketsForKeys.isEmpty)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === nil)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous)
    }
    
    // MARK: Value for Key
    func testValueForKey_returnsValueForKey() {
        let cache = LRUCache<String, Int>()
        
        cache.insertValue(0, forKey: "zero")
        
        XCTAssertEqual(cache.value(forKey: "zero"), 0)
    }
    
    func testValueForKey_bumpsBucketRightAfterHead() {
        let cache = LRUCache<String, Int>()
        
        cache.insertValue(0, forKey: "zero")
        cache.insertValue(1, forKey: "one")
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous!.previous)
        
        cache.value(forKey: "zero")
        
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous!.previous)
    }
    
    // MARK: Evict Value for Key
    func testEvictValueForKey_evictsValueForKey() {
        let cache = LRUCache<String, Int>()
        
        cache.insertValue(0, forKey: "zero")
        cache.insertValue(1, forKey: "one")
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous!.previous)
        
        cache.evictValue(forKey: "zero")
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === nil)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous)
    }
    
    
    // MARK: Evict If Needed
    func testEvictIfNeeded_evictsValue_whenStoredKeyValuePairsCountIsLargerThanMaxCount() {
        let cache = LRUCache<String, Int>()
        
        cache.insertValue(0, forKey: "zero")
        cache.insertValue(1, forKey: "one")
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous!.previous)
        
        cache.maxCount = 1
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous!.previous)
        
        cache.evictIfNeeded()
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === nil)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous)
    }
    
    func testEvictIfNeeded_doesNotEvictsValue_whenStoredKeyValuePairsCountIsEqualToMaxCount() {
        let cache = LRUCache<String, Int>()
        
        cache.insertValue(0, forKey: "zero")
        cache.insertValue(1, forKey: "one")
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous!.previous)
        
        cache.maxCount = 2
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous!.previous)
        
        cache.evictIfNeeded()
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous!.previous)
    }
    
    func testEvictIfNeeded_doesNotEvictsValue_whenStoredKeyValuePairsCountIsSmallerThanMaxCount() {
        let cache = LRUCache<String, Int>()
        
        cache.insertValue(0, forKey: "zero")
        cache.insertValue(1, forKey: "one")
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous!.previous)
        
        cache.maxCount = 3
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous!.previous)
        
        cache.evictIfNeeded()
        
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketHead.next!.next)
        XCTAssertTrue(cache._bucketsForKeys["zero"] === cache._bucketTail.previous)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketHead.next)
        XCTAssertTrue(cache._bucketsForKeys["one"] === cache._bucketTail.previous!.previous)
    }
}
