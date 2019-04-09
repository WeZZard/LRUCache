//
//  LRUCache.swift
//  LRUCache
//
//  Created on 2019/4/9.
//

/// A Least-Recently Used Cache.
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
