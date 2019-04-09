# Least-Recently Used Cache

This is an exercise of implementing [LRU Cache](https://en.wikipedia.org/wiki/Cache_replacement_policies#Least_recently_used_(LRU)) in Swift.

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

### Iterating Cache Contents

Iterating cache contents with `Collection` protocol.

The `LRUCache` itself conforms to `Collection` protocol. You can iterate an
`LRUCache` instance just like iterating any other collection types.

```swift
import LRUCache

let cache = LRUCache<String, Int>(maxCount: 100)

cache.insertValue(0, forKey: "zero")
cache.insertValue(1, forKey: "one")
cache.insertValue(2, forKey: "two")

for (key, value) in cache {
	print("key: \(key) value: \(value).")
}

// Print order is not guaranteed.
```

Iterating cache contents in least-recently used term.

The `LRUCache` has an instance property called `leastRecentlyUsedView` which
returns a sequence whose elements are arranged in least-recently used order.

```swift
import LRUCache

let cache = LRUCache<String, Int>(maxCount: 100)

cache.insertValue(0, forKey: "zero")
cache.insertValue(1, forKey: "one")
cache.insertValue(2, forKey: "two")

cache.value(forKey: "zero")

for (key, value) in cache.leastRecentlyUsedView {
	print("key: \(key) value: \(value).")
}
```

The code above prints

```swift
key: zero value: 0
key: two value: 2
key: one value: 1
```

## License

MIT
