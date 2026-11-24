## Problem

Read a graph and a time interval for each case. Every road has a price that changes linearly with time. Choose the moment that maximizes the total price of the cheapest spanning tree. Print that moment and the total, both with three digits after the decimal point. The earliest moment wins a tie.

The shape of the input:

| Quantity | Bound |
| --- | --- |
| Cities | 1 to 120 |
| Roads | 1 to 820 |
| Moment interval | -10000 to 10000 |
| Time limit | 1292 ms |
| Memory limit | 1536 MB |

The road count keeps one sorted scan cheap per search step.

## Idea

The cheapest spanning tree total is the minimum of one line per spanning tree. That minimum is concave and piecewise linear in the moment. Binary search finds the first moment where the tree slope stops being positive. Each step runs Kruskal once and reads the sum of the chosen slopes.

Each step sorts at most 820 roads and walks them with a disjoint-set structure.

## Why It Works

Each spanning tree contributes one line: its base sum plus the moment times its slope sum. The minimum of lines is concave, so its slope never grows with time. The maximum sits where the slope first reaches zero or turns negative.

Kruskal sorts by price, then by slope. Among tied prices, that order picks the tree with the smallest slope. This equals the slope immediately to the right of the tie. The first moment with a non-positive right slope is the earliest maximum.

A script enumerates all spanning trees of the second sample case:

- The prices 4 - 7j and 3 + 2j cross at j = 1/9.
- The tree total at j = 0 is -2.
- The total at j = 1/9 is -1.
- The total at j = 1/6 is -1.
- The total at j = 1/2 is -7/2.

The flat stretch from 1/9 to 2/9 makes 1/9 the earliest best moment.

## Code

The scanner reads one buffer and keeps the minus sign on negative prices.

```nim
proc nextInt(data: string, position: var int): int =
  while position < data.len and data[position] != '-' and
      (data[position] < '0' or data[position] > '9'):
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return sign * value
```

The signed branch handles prices down to -32000. The loop stops at the first non-digit. The scan costs one pass over its tokens.

Kruskal sorts the roads at the current moment and builds a tree.

```nim
proc findRoot(parent: var seq[int], node: int): int =
  var root = node
  while parent[root] != root:
    root = parent[root]
  var walk = node
  while parent[walk] != walk:
    let nextNode = parent[walk]
    parent[walk] = root
    walk = nextNode
  return root

proc mstAt(moment: float, edgeFrom, edgeTo, edgeA, edgeB: seq[int],
           cityCount, roadCount: int): tuple[total, slope: float] =
  var edgeWeight = newSeq[float](roadCount)
  for i in 0..<roadCount:
    edgeWeight[i] = float(edgeB[i]) + moment * float(edgeA[i])
  var order = newSeq[int](roadCount)
  for i in 0..<roadCount:
    order[i] = i
  order.sort(proc(x, y: int): int =
    if abs(edgeWeight[x] - edgeWeight[y]) > weightTolerance:
      if edgeWeight[x] < edgeWeight[y]: -1 else: 1
    elif edgeA[x] < edgeA[y]: -1
    elif edgeA[x] > edgeA[y]: 1
    else: 0)
  var parent = newSeq[int](cityCount)
  for i in 0..<cityCount:
    parent[i] = i
  var components = cityCount
  var total = 0.0
  var slope = 0.0
  for k in order:
    if components == 1: break
    let leftRoot = findRoot(parent, edgeFrom[k])
    let rightRoot = findRoot(parent, edgeTo[k])
    if leftRoot != rightRoot:
      parent[leftRoot] = rightRoot
      components -= 1
      total += edgeWeight[k]
      slope += float(edgeA[k])
  return (total, slope)
```

The comparator breaks price ties by slope. The guard stops once the tree is whole. The result holds both the price and the right slope.

The search keeps the earliest moment with a non-positive slope.

```nim
  var bestMoment: float
  if mstAt(float(startTime), edgeFrom, edgeTo, edgeA, edgeB,
           cityCount, roadCount).slope <= 0.0:
    bestMoment = float(startTime)
  elif mstAt(float(endTime), edgeFrom, edgeTo, edgeA, edgeB,
             cityCount, roadCount).slope > 0.0:
    bestMoment = float(endTime)
  else:
    var low = float(startTime)
    var high = float(endTime)
    for k in 0..<searchRounds:
      let mid = (low + high) * 0.5
      if mstAt(mid, edgeFrom, edgeTo, edgeA, edgeB,
               cityCount, roadCount).slope <= 0.0:
        high = mid
      else:
        low = mid
    bestMoment = high
```

The loop runs 52 times and halves the interval each step. The two endpoint checks cover a peak at a boundary. `high` always sits at or immediately after the first valid moment.

The final tree gives the price at the chosen moment.

```nim
  var bestValue = mstAt(bestMoment, edgeFrom, edgeTo, edgeA, edgeB,
                        cityCount, roadCount).total
  if abs(bestMoment) < 0.0005: bestMoment = 0.0
  if abs(bestValue) < 0.0005: bestValue = 0.0
  appendOutput(formatFloat(bestMoment, ffDecimal, 3) & " " &
               formatFloat(bestValue, ffDecimal, 3))
  outputBuffer.add '\n'
```

Both numbers print three digits. The near-zero checks remove a negative zero. One buffer flushes every 256 KiB.

## Complexity

Parsing reads the whole input once and costs O(total tokens) time. One slope query sorts at most m roads, so it costs O(m log m + n) time. A case runs 54 queries, so it costs O(54 * m log m) time. Space is O(m + n) per case plus the two I/O buffers.

A grid search that rebuilds a tree at thousands of moments costs far more tree builds per case.
