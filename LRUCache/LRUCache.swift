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
    internal var _bucketHead: _Bucket<Key, Value>
    internal var _bucketTail: _Bucket<Key, Value>
    
    internal var _bucketsForKeys: [Key : _Bucket<Key, Value>]
    
    /// The max key-value pairs can be stored in this cache. `0` means no
    /// limit.
    ///
    public var maxCount: Int
    
    public init(maxCount: Int = 0) {
        self.maxCount = maxCount
        _bucketHead = .init()
        _bucketTail = .init()
        _bucketHead.next = _bucketTail
        _bucketTail.previous = _bucketHead
        _bucketsForKeys = [:]
    }
    
    /// Inserts a `value` for `key` to the cache. Returns the old value
    /// if there is.
    ///
    /// - Parameter value: The value to be inserted.
    ///
    /// - Parameter key: The key of the inserted value.
    ///
    /// - Returns: The old value of the `key` if there is.
    ///
    /// Inserting values which have already been in cache with same keys
    /// makes the cache delays the eviction of those key-value pairs (If
    /// `maxCount` is larger than 0).
    ///
    @discardableResult
    public func insertValue(_ value: Value, forKey key: Key) -> Value? {
        var oldValue: Value?
        if let _bucket = _bucketsForKeys[key] {
            oldValue = _bucket.keyValuePair.value
            _bucket.keyValuePair = (key, value)
            _removeBucket(_bucket)
            _insertBucket(_bucket)
        } else {
            let _bucket = _Bucket(keyValuePair: (key, value))
            _bucketsForKeys[key] = _bucket
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
        if let _bucket = _bucketsForKeys[key] {
            _bucketsForKeys[key] = nil
            _removeBucket(_bucket)
            return _bucket.keyValuePair.value
        }
        return nil
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
        if let _bucket = _bucketsForKeys[key] {
            _removeBucket(_bucket)
            _insertBucket(_bucket)
            return _bucket.keyValuePair.value
        }
        return nil
    }
    
    /// Evicts key-value pairs until the stored key-value pairs are less
    /// than `maxCount`.
    ///
    public func evictIfNeeded() {
        guard maxCount > 0 else { return }
        
        while _bucketsForKeys.count > maxCount {
            let _bucket = _bucketTail.previous!
            _removeBucket(_bucket)
            _bucketsForKeys[_bucket.keyValuePair.key] = nil
        }
    }
    
    internal func _insertBucket(_ bucket: _Bucket<Key, Value>) {
        let currentFirstBucket = _bucketHead.next!
        
        _bucketHead.next = bucket
        bucket.previous = _bucketHead
        
        bucket.next = currentFirstBucket
        currentFirstBucket.previous = bucket
    }
    
    internal func _removeBucket(_ bucket: _Bucket<Key, Value>) {
        let previous = bucket.previous!
        
        let next = bucket.next!
        
        previous.next = next
        next.previous = previous
        
        bucket.next = nil
        bucket.previous = nil
    }
}

// MARK: Collection

public struct LRUCacheIndex<Key: Hashable, Value>: Comparable, Hashable {
    internal let _impl: DictionaryIndex<Key, _Bucket<Key, Value>>
    
    internal init(impl: DictionaryIndex<Key, _Bucket<Key, Value>>) {
        _impl = impl
    }
    
    public static func < (lhs: LRUCacheIndex, rhs: LRUCacheIndex) -> Bool {
        return lhs._impl < rhs._impl
    }
}

extension LRUCache: Collection {
    public typealias Index = LRUCacheIndex<Key, Value>
    
    public typealias Element = (key: Key, value: Value)
    
    public var startIndex: Index {
        return LRUCacheIndex(impl: _bucketsForKeys.startIndex)
    }
    
    public var endIndex: Index {
        return LRUCacheIndex(impl: _bucketsForKeys.endIndex)
    }
    
    public func index(after i: Index) -> Index {
        return Index(impl: _bucketsForKeys.index(after: i._impl))
    }
    
    public subscript(index: Index) -> Element {
        let (_, bucket) = _bucketsForKeys[index._impl]
        return bucket.keyValuePair
    }
}

// MARK: Least-Recently Used View

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
/// let cache = LRUCache<String, Int>(maxCount: 10)
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
    internal let _cache: LRUCache<Key, Value>
    
    public init(cache: LRUCache<Key, Value>) {
        _cache = cache
    }
    
    public typealias Iterator = LRUCacheLeastRecentlyUsedViewIterator<Key, Value>
    
    public __consuming func makeIterator() -> Iterator {
        return Iterator(cache: _cache)
    }
}

/// The least-recently used view iterator of an `LRUCache` instance.
///
public struct LRUCacheLeastRecentlyUsedViewIterator<Key: Hashable, Value>:
    IteratorProtocol
{
    internal let _cache: LRUCache<Key, Value>
    
    internal unowned var current: _Bucket<Key, Value>
    
    public init(cache: LRUCache<Key, Value>) {
        _cache = cache
        current = _cache._bucketHead.next!
    }
    
    public typealias Element = (key: Key, value: Value)
    
    public mutating func next() -> Element? {
        if let keyValuePair = current.keyValuePair {
            current = current.next!
            return keyValuePair
        }
        return nil
    }
}

extension LRUCache {
    /// Returns a view of the cache which is a sequence of the stored
    /// key-value pairs arranged in least-recently used order.
    ///
    public var leastRecentlyUsedView: LRUCacheLeastRecentlyUsedView<Key, Value> {
        return LRUCacheLeastRecentlyUsedView(cache: self)
    }
}

// MARK: - _Bucket

internal class _Bucket<Key: Hashable, Value> {
    internal weak var previous: _Bucket?
    
    internal var next: _Bucket?
    
    internal var keyValuePair: (key: Key, value: Value)!
    
    internal init(keyValuePair: (key: Key, value: Value)? = nil) {
        self.keyValuePair = keyValuePair
    }
    
    deinit {
        var succeedingBuckets = [self]
        
        var current: _Bucket? = self
        
        while let next = current?.next {
            succeedingBuckets.append(next)
            current = next.next
        }
        
        for each in succeedingBuckets.reversed() {
            each.next = nil
            each.previous = nil
        }
    }
}
