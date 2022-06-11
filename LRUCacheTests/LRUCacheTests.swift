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
  
  func testInsertValueForKey_updatesValues() {
    let cache = LRUCache<String, Int>()
    
    XCTAssertEqualLeastRecentlyUsedView(cache.leastRecentlyUsedView, [])
    
    cache.insertValue(0, forKey: "zero")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("zero", 0)]
    )
  }
  
  func testInsertValueForKey_evictsValueIfNeeded() {
    let cache = LRUCache<String, Int>(totalWeight: 10)
    
    XCTAssertEqualLeastRecentlyUsedView(cache.leastRecentlyUsedView, [])
    
    cache.insertValue(0, forKey: "zero", weight: 9)
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("zero", 0)]
    )
    cache.insertValue(1, forKey: "one")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
    cache.insertValue(2, forKey: "two")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("two", 2), ("one", 1)]
    )
  }
  
  func testInsertValueForKey_updatesUsedWeight() {
    let cache = LRUCache<String, Int>()
    
    XCTAssertEqual(cache.usedWeight, 0)
    
    cache.insertValue(0, forKey: "zero")
    
    XCTAssertEqual(cache.usedWeight, 1)
    
    cache.insertValue(0, forKey: "zero", weight: 10)
    
    XCTAssertEqual(cache.usedWeight, 10)
  }
  
  func testInsertValueForKey_formsLeastRecentlyUsedView() {
    let cache = LRUCache<String, Int>()
    
    XCTAssertEqualLeastRecentlyUsedView(cache.leastRecentlyUsedView, [])
    
    cache.insertValue(0, forKey: "zero")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("zero", 0)]
    )
  }
  
  func testInsertValueForKey_updatesLeastRecentlyUsedView() {
    let cache = LRUCache<String, Int>()
    
    XCTAssertEqualLeastRecentlyUsedView(cache.leastRecentlyUsedView, [])
    
    cache.insertValue(0, forKey: "zero")
    cache.insertValue(1, forKey: "one")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
    cache.insertValue(0, forKey: "zero")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("zero", 0), ("one", 1)]
    )
  }
  
  // MARK: Value for Key
  func testValueForKey_returnsValueForKey() {
    let cache = LRUCache<String, Int>()
    
    cache.insertValue(0, forKey: "zero")
    
    XCTAssertEqual(cache.value(forKey: "zero"), 0)
  }
  
  func testValueForKey_updatesLeastRecentlyUsedView() {
    let cache = LRUCache<String, Int>()
    
    cache.insertValue(0, forKey: "zero")
    cache.insertValue(1, forKey: "one")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
    cache.value(forKey: "zero")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("zero", 0), ("one", 1)]
    )
  }
  
  // MARK: Evict Value for Key
  
  func testEvictValueForKey_evictsValueForKey() {
    let cache = LRUCache<String, Int>()
    
    cache.insertValue(0, forKey: "zero")
    cache.insertValue(1, forKey: "one")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
    cache.evictValue(forKey: "zero")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1)]
    )
  }
  
  
  // MARK: Evict If Needed
  func testEvictIfNeeded_evictsValue_whenUsedWeightIsLargerThanTotalWeight() {
    let cache = LRUCache<String, Int>()
    
    cache.insertValue(0, forKey: "zero")
    cache.insertValue(1, forKey: "one")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
    cache.totalWeight = 1
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
    cache.evictIfNeeded()
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1)]
    )
    
  }
  
  func testEvictIfNeeded_doesNotEvictsValue_whenUsedWeightIsEqualToTotalWeight() {
    let cache = LRUCache<String, Int>()
    
    cache.insertValue(0, forKey: "zero")
    cache.insertValue(1, forKey: "one")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
    cache.totalWeight = 2
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
    cache.evictIfNeeded()
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
  }
  
  func testEvictIfNeeded_doesNotEvictsValue_whenUsedWeightIsSmallerThanTotalWeight() {
    let cache = LRUCache<String, Int>()
    
    cache.insertValue(0, forKey: "zero")
    cache.insertValue(1, forKey: "one")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
    cache.totalWeight = 3
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
    cache.evictIfNeeded()
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
  }
  
  // MARK: Least-Recently Used View
  
  func testLeastRecentlyUsedView_returnsCacheStoredKeyValuePairsInLeastRecentlyUsedOrder() {
    let cache = LRUCache<String, Int>()
    
    cache.insertValue(0, forKey: "zero")
    cache.insertValue(1, forKey: "one")
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("one", 1), ("zero", 0)]
    )
    
    cache.value(forKey: "zero")
    
    
    XCTAssertEqualLeastRecentlyUsedView(
      cache.leastRecentlyUsedView,
      [("zero", 0), ("one", 1)]
    )
  }
  
  // MARK: Utilities
  
  func XCTAssertEqualLeastRecentlyUsedView<
    View1: Sequence,
    View2: Sequence,
    Key: Hashable,
    Value: Equatable
  >(
    _ lhs: View1,
    _ rhs: View2,
    file: StaticString = #file,
    line: UInt = #line
  ) where View1.Element == (key: Key, value: Value), View2.Element == (Key, Value) {
    func compareElement(_ lhs: (Key, Value), _ rhs: (Key, Value)) -> Bool {
      return lhs.0 == rhs.0 && lhs.1 == rhs.1
    }
    XCTAssertTrue(lhs.elementsEqual(rhs, by: compareElement), file: file, line: line)
  }
  
}
