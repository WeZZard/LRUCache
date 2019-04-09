# Least-Recently Used Cache

This is an excersice of implementing [LRU Cache](https://en.wikipedia.org/wiki/Cache_replacement_policies#Least_recently_used_(LRU)) in Swift.

## Usage


### Managing Cache Contents

Inserting values for keys.

```swift
import LRUCache

let cache = LRUCache<String, Int>(maxCount: 100)

cache.insertValue(0, forKey: "zero")

```

Evicting values for keys.

```swift
cache.evictValue(forKey: "zero")
```

Accessing values for keys.

```swift
cache.value(forKey: "zero")
```
