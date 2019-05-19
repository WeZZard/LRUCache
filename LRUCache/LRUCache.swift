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
    internal typealias _KeyValuePair = (key: Key, value: Value)
    
    internal var _bucketOffsetsForKeys: [Key : Int]
    
    internal let _storage: _LRUCacheBucketStorage<_KeyValuePair>
    
    /// The max key-value pairs can be stored in this cache. `0` means no
    /// limit.
    ///
    public var maxCount: Int
    
    public init(maxCount: Int = 0) {
        self.maxCount = maxCount
        _bucketOffsetsForKeys = [:]
        _storage = _LRUCacheBucketStorage()
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
        if let bucketOffset = _bucketOffsetsForKeys[key] {
            let oldKeyValuePair = _storage.remove(at: bucketOffset)
            oldValue = oldKeyValuePair.value
        }
        let newBucketOffset = _storage.pushFront((key, value))
        _bucketOffsetsForKeys[key] = newBucketOffset
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
        if let bucketOffset = _bucketOffsetsForKeys[key] {
            _bucketOffsetsForKeys[key] = nil
            let (_, value) = _storage.remove(at: bucketOffset)
            return value
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
        if let bucketOffset = _bucketOffsetsForKeys[key] {
            let keyValuePair = _storage.remove(at: bucketOffset)
            let newBucketOffset = _storage.pushFront(keyValuePair)
            _bucketOffsetsForKeys[key] = newBucketOffset
            return keyValuePair.value
        }
        return nil
    }
    
    /// Evicts key-value pairs until the stored key-value pairs are less
    /// than `maxCount`.
    ///
    public func evictIfNeeded() {
        guard maxCount > 0 else { return }
        
        while _bucketOffsetsForKeys.count > maxCount {
            let (key, _) = _storage.popBack()
            _bucketOffsetsForKeys[key] = nil
        }
    }
}

// MARK: Collection

public struct LRUCacheIndex<Key: Hashable, Value>: Comparable, Hashable {
    internal let _impl: DictionaryIndex<Key, Int>
    
    internal init(impl: DictionaryIndex<Key, Int>) {
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
        return LRUCacheIndex(impl: _bucketOffsetsForKeys.startIndex)
    }
    
    public var endIndex: Index {
        return LRUCacheIndex(impl: _bucketOffsetsForKeys.endIndex)
    }
    
    public func index(after i: Index) -> Index {
        return Index(impl: _bucketOffsetsForKeys.index(after: i._impl))
    }
    
    public subscript(index: Index) -> Element {
        let (_, bucketOffset) = _bucketOffsetsForKeys[index._impl]
        return _storage._withMutableBucket(at: bucketOffset)[0].element!
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
    
    internal var _currentBucketOffset: Int
    
    public init(cache: LRUCache<Key, Value>) {
        _cache = cache
        _currentBucketOffset = _cache._storage._headOffset
    }
    
    public typealias Element = (key: Key, value: Value)
    
    public mutating func next() -> Element? {
        if _currentBucketOffset != -1 {
            let currentBucketPtr = _cache._storage._withMutableBucket(at: _currentBucketOffset)
            if let keyValuePair = currentBucketPtr[0].element {
                _currentBucketOffset = currentBucketPtr[0].nextBucketOffset
                return keyValuePair
            }
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
