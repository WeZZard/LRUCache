//
//  _LRUCacheBucket.swift
//  LRUCache
//
//  Created on 2019/5/20.
//

struct _LRUCacheBucket<Element> {
    var previousBucketOffset: Int
    var nextBucketOffset: Int
    var element: Element?
}
