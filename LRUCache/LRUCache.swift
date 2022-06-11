//
//  LRUCache.swift
//  LRUCache
//
//  Created on 2019/4/9.
//

// MARK: - LRUCache

/// A Least-Recently Used Cache. Not thread-safe.
///
public class LRUCache<Key: Hashable, Value> {
  
  fileprivate var head: LRUBucket<Key, Value>
  
  fileprivate var tail: LRUBucket<Key, Value>
  
  fileprivate var bucketsForKeys: [Key : LRUBucket<Key, Value>]
  
  /// The max key-value pairs can be stored in this cache. `0` means no
  /// limit.
  ///
  public var totalWeight: Int
  
  public private(set) var usedWeight: Int
  
  /// Initializes an `LRUCache` instance.
  ///
  /// - Parameter totalWeight: The max key-value pairs can be stored in this
  /// cache. `0` means no limit.
  ///
  public init(totalWeight: Int = 0) {
    self.totalWeight = totalWeight
    self.usedWeight = 0
    self.head = .init()
    self.tail = .init()
    self.head.next = tail
    self.tail.previous = head
    self.bucketsForKeys = [:]
  }
  
  /// Inserts a `value` for `key` to the cache. Returns the old value
  /// if there is.
  ///
  /// - Parameter value: The value to be inserted.
  ///
  /// - Parameter key: The key of the inserted value.
  ///
  /// - Parameter weight: The weight of the inserted value. `nil` for `1`.
  ///
  /// - Returns: The old value of the `key` if there is.
  ///
  /// Inserting values which have already been in cache with same keys
  /// makes the cache delays the eviction of those key-value pairs (If
  /// `maxCount` is larger than 0).
  ///
  @discardableResult
  public func insertValue(
    _ value: Value,
    forKey key: Key,
    weight weightOrNil: Int? = nil
  ) -> Value? {
    let newWeight = checkedWeight(weightOrNil)
    var oldValue: Value?
    if let _bucket = bucketsForKeys[key] {
      oldValue = _bucket.contents.value
      _removeBucket(_bucket)
      _bucket.contents = (key, value, newWeight)
      _insertBucket(_bucket)
    } else {
      let _bucket = LRUBucket(contents: (key, value, newWeight))
      bucketsForKeys[key] = _bucket
      _insertBucket(_bucket)
    }
    evictIfNeeded()
    return oldValue
  }
  
  /// Evicts a `value` for `key` in the cache.
  ///
  /// - Parameter key: The key of the value to be evicted.
  ///
  /// - Returns: The evicted value if the cache contains a paired value
  /// for `key`.
  ///
  @discardableResult
  public func evictValue(forKey key: Key) -> Value? {
    guard let bucket = bucketsForKeys[key] else {
      return nil
    }
    bucketsForKeys[key] = nil
    _removeBucket(bucket)
    return bucket.contents.value
  }
  
  /// Returns a value for `key` in the cache.
  ///
  /// - Parameter key: The key of the value to be evicted.
  ///
  /// - Returns: The value if the cache contains a paired value for
  /// `key`.
  ///
  /// Accessing values for keys with this function would delay the
  /// eviction of the paired value of `key` (If `maxCount` is larger
  /// than 0).
  ///
  @discardableResult
  public func value(forKey key: Key) -> Value? {
    guard let bucket = bucketsForKeys[key] else {
      return nil
    }
    _removeBucket(bucket)
    _insertBucket(bucket)
    return bucket.contents.value
  }
  
  /// Evicts key-value pairs until the stored key-value pairs are less
  /// than `maxCount`.
  ///
  public func evictIfNeeded() {
    guard totalWeight > 0 else {
      return
    }
    
    while usedWeight > totalWeight {
      let mostNotUsedBucket = tail.previous!
      _removeBucket(mostNotUsedBucket)
      bucketsForKeys[mostNotUsedBucket.contents.key] = nil
    }
  }
  
  internal func _insertBucket(_ bucket: LRUBucket<Key, Value>) {
    usedWeight += bucket.contents.weight
    
    let currentFirstBucket = head.next!
    
    head.next = bucket
    bucket.previous = head
    
    bucket.next = currentFirstBucket
    currentFirstBucket.previous = bucket
  }
  
  internal func _removeBucket(_ bucket: LRUBucket<Key, Value>) {
    usedWeight -= bucket.contents.weight
    
    let previous = bucket.previous!
    
    let next = bucket.next!
    
    previous.next = next
    next.previous = previous
    
    bucket.next = nil
    bucket.previous = nil
  }
  
  @inline(__always)
  private func checkedWeight(_ weight: Int?) -> Int {
    if let weight = weight {
      precondition(weight >= 0)
      return weight
    } else {
      return 1
    }
  }
}

// MARK: Least-Recently Used View

extension LRUCache {
  
  /// Returns a view of the cache which is a sequence of the stored
  /// key-value pairs arranged in least-recently used order.
  ///
  public var leastRecentlyUsedView: LRUCacheLeastRecentlyUsedView<Key, Value> {
    return LRUCacheLeastRecentlyUsedView(cache: self)
  }
  
}

/// The least-recently used view of an `LRUCache` instance.
///
/// Iterator Invalidation
/// =====================
///
/// The `LRUCache` class does not hornor COW (copy-on-write). This leads
/// an `LRUCacheLeastRecentlyUsedView` instance which holds a strong
/// reference to the cache instance doesn't make the cache instance to be
/// copied when the cache instance is scheduled to be viewed in
/// least-recently used and then wrriten.
///
/// You may think the variable `leastRecentlyUsedView` in following code
/// returns `[1, 0]`, but it returns `[0, 1]`.
///
/// ```
/// let cache = LRUCache<String, Int>(totalWeight: 10)
///
/// cache.insertValue(0, forKey: "zero")
///
/// cache.insertValue(1, forKey: "one")
///
/// let leastRecentlyUsedView = cache.leastRecentlyUsedView
///
/// cache.value(forKey: "zero")
///
/// print(Array(leastRecentlyUsedView))
/// ```
///
public struct LRUCacheLeastRecentlyUsedView<Key: Hashable, Value>: Sequence {
  
  private let cache: LRUCache<Key, Value>
  
  public init(cache: LRUCache<Key, Value>) {
    self.cache = cache
  }
  
  public typealias Iterator = LRUCacheLeastRecentlyUsedViewIterator<Key, Value>
  
  public __consuming func makeIterator() -> Iterator {
    return Iterator(cache: cache)
  }
}

/// The least-recently used view iterator of an `LRUCache` instance.
///
public struct LRUCacheLeastRecentlyUsedViewIterator<Key: Hashable, Value>:
  IteratorProtocol
{
  
  internal let cache: LRUCache<Key, Value>
  
  internal unowned var current: LRUBucket<Key, Value>
  
  public init(cache: LRUCache<Key, Value>) {
    self.cache = cache
    self.current = cache.head.next!
  }
  
  public typealias Element = (key: Key, value: Value)
  
  public mutating func next() -> Element? {
    guard let (key, value, _) = current.contents else {
      return nil
    }
    current = current.next!
    return (key, value)
  }
}

// MARK: - _Bucket

internal class LRUBucket<Key: Hashable, Value> {
  
  internal weak var previous: LRUBucket?
  
  internal var next: LRUBucket?
  
  internal var contents: (key: Key, value: Value, weight: Int)!
  
  internal init(contents: (key: Key, value: Value, weight: Int)? = nil) {
    self.contents = contents
  }
  
  deinit {
    var endOrNil: LRUBucket? = self
    
    while let next = endOrNil?.next {
      endOrNil = next.next
    }
    
    while let end = endOrNil {
      end.previous?.next = nil
      endOrNil = end.previous
      end.previous = nil
    }
  }
  
}
