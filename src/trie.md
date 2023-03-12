# Examples

Node types:

```draw
null
Leaf: [<key>, <value>]
Branch: [<node0>, <node1>, ... <node15>, <value>]
Extension [<key>, <node>]
```

## Single leaf node

```draw
put(0x12345, "value1")

Leaf [0x12345, "value1"]
```

## Branch and leaf

```draw
put(0x5, "value1")
put(0x12345, "value2")

Branch: [null, <Leaf1>, null, ..., "value1"]
Leaf1: [0x2345, "value2"]
```
