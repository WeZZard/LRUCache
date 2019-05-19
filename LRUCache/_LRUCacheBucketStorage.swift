//
//  _LRUCacheBucketStorage.swift
//  LRUCache
//
//  Created on 2019/5/17.
//

internal class _LRUCacheBucketStorage<Element> {
    internal typealias _Bucket = _LRUCacheBucket<Element>
    
    internal var _headOffset: Int
    
    internal var _tailOffset: Int
    
    internal var _reuseHeadOffset: Int
    
    internal var _reuseTailOffset: Int
    
    internal var _buffer: UnsafeMutablePointer<_Bucket>!
    
    internal var _count: Int
    
    internal var _capacity: Int
    
    init() {
        _headOffset = -1
        _tailOffset = -1
        _reuseHeadOffset = -1
        _reuseTailOffset = -1
        _buffer = nil
        _count = 0
        _capacity = 0
    }
    
    convenience init(capacity: Int) {
        self.init()
        _growBuffer(to: capacity)
    }
    
    deinit {
        if let buffer = _buffer {
            buffer.deallocate()
        }
    }
    
    func _growBufferIfNeeded() {
        precondition(_reuseHeadOffset == -1)
        precondition(_reuseTailOffset == -1)
        
        let newCapacity = max(1, _capacity + ((_capacity + 1) >> 1))
        
        _growBuffer(to: newCapacity)
    }
    
    func _growBuffer(to capacity: Int) {
        let oldCapacity = _capacity
        
        let newCapacity = capacity
        
        if capacity > oldCapacity {
            let oldBuffer = _buffer
            
            let newBuffer = UnsafeMutablePointer<_Bucket>.allocate(capacity: newCapacity)
            
            if let oldBuffer = oldBuffer {
                newBuffer.initialize(from: oldBuffer, count: oldCapacity)
            }
            
            let newFirstBucket = newBuffer.advanced(by: oldCapacity)
            newFirstBucket.pointee.previousBucketOffset = _reuseTailOffset
            
            for offset in (oldCapacity + 1)..<newCapacity {
                let bucket = newBuffer.advanced(by: offset)
                bucket.pointee.previousBucketOffset = offset - 1
            }
            
            let newLastBucket = newBuffer.advanced(by: max(0, newCapacity - 1))
            newLastBucket.pointee.nextBucketOffset = -1
            
            for offset in oldCapacity..<max(0, newCapacity - 1) {
                let bucket = newBuffer.advanced(by: offset)
                bucket.pointee.nextBucketOffset = offset + 1
            }
            
            oldBuffer?.deinitialize(count: oldCapacity)
            oldBuffer?.deallocate()
            
            _buffer = newBuffer
            _reuseHeadOffset = _reuseHeadOffset == -1 ? oldCapacity : _reuseHeadOffset
            _reuseTailOffset = newCapacity
            _capacity = newCapacity
        }
    }
    
    internal func _withMutableBucket(at index: Int) -> UnsafeMutablePointer<_Bucket> {
        precondition(index >= 0)
        return _buffer.advanced(by: index)
    }
    
    // MARK: Front
    func _dequeueFrontReusableBucketOffset() -> Int {
        if _reuseHeadOffset == -1 {
            _growBufferIfNeeded()
        }
        
        precondition(_reuseHeadOffset != -1)
        
        let reusableBucketOffset = _reuseHeadOffset
        let reusableBucketPtr = _withMutableBucket(at: reusableBucketOffset)
        
        let nextReusableBucketOffset = reusableBucketPtr[0].nextBucketOffset
        
        if nextReusableBucketOffset != -1 {
            let nextReusableHeadBucketPtr = _withMutableBucket(at: nextReusableBucketOffset)
            nextReusableHeadBucketPtr[0].previousBucketOffset = -1
        }
        
        _reuseHeadOffset = nextReusableBucketOffset
        reusableBucketPtr[0].nextBucketOffset = -1
        
        return reusableBucketOffset
    }
    
    func _enqueueFrontUnusedBucket(at unusedBucketOffset: Int) {
        if _reuseHeadOffset != -1 {
            let currentReusableHeadBucketPtr = _withMutableBucket(at: _reuseHeadOffset)
            currentReusableHeadBucketPtr[0].previousBucketOffset = unusedBucketOffset
        }
        
        let unusedBucketPtr = _withMutableBucket(at: unusedBucketOffset)
        unusedBucketPtr[0].element = nil
        unusedBucketPtr[0].nextBucketOffset = _reuseHeadOffset
        unusedBucketPtr[0].previousBucketOffset = -1
        
        _reuseHeadOffset = unusedBucketOffset
    }
    
    func pushFront(_ element: Element) -> Int {
        let reusableFrontBucketOffset = _dequeueFrontReusableBucketOffset()
        
        let reusableFrontBucketPtr = _withMutableBucket(at: reusableFrontBucketOffset)
        
        reusableFrontBucketPtr[0].element = element
        reusableFrontBucketPtr[0].nextBucketOffset = _headOffset
        reusableFrontBucketPtr[0].previousBucketOffset = -1
        
        if _headOffset != -1 {
            let currentHeadBucketPtr = _withMutableBucket(at: _headOffset)
            currentHeadBucketPtr[0].previousBucketOffset = reusableFrontBucketOffset
        }
        
        _headOffset = reusableFrontBucketOffset
        
        _count += 1
        
        return _headOffset
    }
    
    func popFront() -> Element {
        precondition(_headOffset != -1, "Expecting list node.")
        
        let headBucketPtr = _withMutableBucket(at: _headOffset)
        
        let next = headBucketPtr[0].nextBucketOffset
        let element = headBucketPtr[0].element
        
        precondition(element != nil, "Bad list node.")
        
        if next != -1 {
            let nextBucketPtr = _withMutableBucket(at: next)
            nextBucketPtr[0].previousBucketOffset = -1
        }
        
        _enqueueFrontUnusedBucket(at: _headOffset)
        
        _headOffset = next
        
        _count -= 1
        
        return element!
    }
    
    func peakFront() -> Element {
        precondition(_headOffset != -1, "Expecting list node.")
        
        let bucketPtr = _withMutableBucket(at: _headOffset)
        
        let element = bucketPtr[0].element
        
        precondition(element != nil, "Bad list node.")
        
        return element!
    }
    
    // MARK: Back
    func _dequeueBackReusableBucketOffset() -> Int {
        if _reuseTailOffset == -1 {
            _growBufferIfNeeded()
        }
        
        precondition(_reuseTailOffset != -1)
        
        let reusableBucketOffset = _reuseTailOffset
        let reusableBucketPtr = _withMutableBucket(at: reusableBucketOffset)
        
        let previousReusableBucketOffset = reusableBucketPtr[0].previousBucketOffset
        
        if previousReusableBucketOffset != -1 {
            let previousReusableHeadBucketPtr = _withMutableBucket(at: previousReusableBucketOffset)
            previousReusableHeadBucketPtr[0].nextBucketOffset = -1
        }
        
        _reuseTailOffset = previousReusableBucketOffset
        reusableBucketPtr[0].previousBucketOffset = -1
        
        return reusableBucketOffset
    }
    
    func _enqueueBackUnusedBucket(at unusedBucketOffset: Int) {
        if _reuseTailOffset != -1 {
            let currentReusableTailBucketPtr = _withMutableBucket(at: _reuseTailOffset)
            currentReusableTailBucketPtr[0].nextBucketOffset = unusedBucketOffset
        }
        
        let unusedBucketPtr = _withMutableBucket(at: unusedBucketOffset)
        unusedBucketPtr[0].element = nil
        unusedBucketPtr[0].previousBucketOffset = _reuseHeadOffset
        unusedBucketPtr[0].nextBucketOffset = -1
        
        _reuseTailOffset = unusedBucketOffset
    }
    
    func pushBack(_ element: Element) -> Int {
        let reusableBackBucketOffset = _dequeueBackReusableBucketOffset()
        
        let reusableBackBucketPtr = _withMutableBucket(at: reusableBackBucketOffset)
        
        reusableBackBucketPtr[0].element = element
        reusableBackBucketPtr[0].nextBucketOffset = _tailOffset
        reusableBackBucketPtr[0].previousBucketOffset = -1
        
        if _tailOffset != -1 {
            let currentTailBucketPtr = _withMutableBucket(at: _tailOffset)
            currentTailBucketPtr[0].nextBucketOffset = reusableBackBucketOffset
        }
        
        _tailOffset = reusableBackBucketOffset
        
        _count += 1
        
        return _tailOffset
    }
    
    func popBack() -> Element {
        precondition(_headOffset != -1, "Expecting list node.")
        
        let tailBucketPtr = _withMutableBucket(at: _tailOffset)
        
        let previous = tailBucketPtr[0].previousBucketOffset
        let element = tailBucketPtr[0].element
        
        precondition(element != nil, "Bad list node.")
        
        if previous != -1 {
            let previousBucketPtr = _withMutableBucket(at: previous)
            previousBucketPtr[0].nextBucketOffset = -1
        }
        
        _enqueueBackUnusedBucket(at: _tailOffset)
        
        _tailOffset = previous
        
        _count -= 1
        
        return element!
    }
    
    func peakBack() -> Element {
        precondition(_tailOffset != -1, "Expecting list node.")
        
        let bucketPtr = _withMutableBucket(at: _tailOffset)
        
        let element = bucketPtr[0].element
        
        precondition(element != nil, "Bad list node.")
        
        return element!
    }
    
    // MARK: Random Accessing
    func remove(at offset: Int) -> Element {
        let previousBucketOffset = _buffer![offset].previousBucketOffset
        let nextBucketOffset = _buffer![offset].nextBucketOffset
        
        let element = _buffer![offset].element!
        
        if previousBucketOffset != -1 {
            _buffer[previousBucketOffset].nextBucketOffset = nextBucketOffset
        }
        
        if nextBucketOffset != -1 {
            _buffer[nextBucketOffset].previousBucketOffset = previousBucketOffset
        }
        
        return element
    }
}



