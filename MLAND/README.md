# MLAND — Land for Motorways (SPOJ)

<https://www.spoj.com/problems/MLAND/>

## Problem

Road prices change linearly with time, so the cheapest spanning tree changes too. Find the moment when that total price peaks.

Read `t` cases. Each gives the city count, the road count, and a time interval. Each road line gives two endpoints and two coefficients.

Its price at moment `j` is `b + a * j`. Print the best moment and the tree total, both with three digits after the decimal point. The earliest moment wins a tie.

The bounds and judge limits:

| Quantity | Bound |
| --- | --- |
| Cities | 1 to 120 |
| Roads | 1 to 820 |
| Moment interval | -10000 to 10000 |
| Time limit | 1292 ms |
| Memory limit | 1536 MB |

The road count keeps one sorted scan cheap per search step.

The sample case:

```
2
5 6
0 5
1 0 -6 -4
2 0 3 -3
3 0 1 5
3 1 -2 -3
4 1 -3 -2
4 3 -2 -3
5 7
-20 20
1 0 1 2
2 1 -7 4
3 1 -9 0
3 2 4 9
4 1 0 -2
4 2 2 3
4 3 6 -5
```

```
0.000 -13.000
0.111 -1.000
```

## Idea

Trace the lower edge of a pile of straight lines; that edge bends down at most once.

Each spanning tree contributes one line of time. The minimum of those lines is concave (its slope never grows), so the peak sits where the slope first reaches zero. Binary search finds that moment.

Each step runs Kruskal's algorithm (sort roads by price, then join components) and reads the sum of chosen slopes.

Each step sorts at most 820 roads, costing O(m log m + n). A grid search that rebuilds a tree at thousands of moments costs far more.

## Why It Works

Five facts prove the search exact.

1. Each spanning tree contributes a line: its base sum plus the moment times its slope sum. The minimum of lines stays concave, so its slope never grows.
2. The maximum sits where the slope first reaches zero or turns negative. That moment is the earliest maximum.
3. Kruskal sorts by price, then by slope. Among tied prices, that order picks the tree with the smallest slope. That slope equals the one immediately right of the tie.
4. Two endpoint checks cover a peak at either boundary. Binary search then halves the interval until the earliest valid moment remains.
5. Printed values use three digits, and a near-zero check removes a negative zero before formatting.

The values and their roles:

| Term | Meaning |
| --- | --- |
| `mstAt` | returns tree total and right slope at one moment |
| `edgeWeight` | price `b + a * j` of a road at moment `j` |
| `slope` | sum of coefficients `a` over the chosen roads |
| `components` | count of disjoint sets left during Kruskal |
| `searchRounds` | 52 binary-search steps |
| `weightTolerance` | 1e-6 gap for treating two prices as equal |
| `bestMoment` | earliest moment with a non-positive slope |

The comparator inside `mstAt` keeps slope ties resolved in one pass.

A script enumerates spanning trees for the second sample case:

```
prices 4 - 7j and 3 + 2j cross at j = 1/9
tree total at j = 0      is -2
tree total at j = 1/9    is -1
tree total at j = 1/6    is -1
tree total at j = 1/2    is -7/2
answer: 0.111 -1.000
```

The total stays flat from 1/9 to 2/9, so 1/9 is the earliest best moment.

## Code

**Scanner and constants.** One buffer holds the input and the scanner keeps minus signs.

```nim
import algorithm, strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const weightTolerance = 1e-6
const searchRounds = 52

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

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

**Buffered output.** A single string collects answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at 256 KiB, so one write serves many lines. Each case appends one formatted line.

**Kruskal at one moment.** A tree is built and both its price and slope return.

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

The comparator breaks price ties by slope. The guard stops once the tree is whole. `findRoot` compresses paths, so each lookup stays cheap.

**Case input.** Four integers start each case, then one line per road.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let startTime = nextInt(inputData, scanPos)
  let endTime = nextInt(inputData, scanPos)
  var edgeFrom = newSeq[int](roadCount)
  var edgeTo = newSeq[int](roadCount)
  var edgeA = newSeq[int](roadCount)
  var edgeB = newSeq[int](roadCount)
  for i in 0..<roadCount:
    edgeFrom[i] = nextInt(inputData, scanPos)
    edgeTo[i] = nextInt(inputData, scanPos)
    edgeA[i] = nextInt(inputData, scanPos)
    edgeB[i] = nextInt(inputData, scanPos)
```

Each road stores two endpoints and the two price coefficients. The arrays are reused across cases by reallocation once per case. Parsing costs one pass over the token stream.

**Binary search.** The loop keeps the earliest moment with a non-positive slope.

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

The loop runs 52 times and halves the interval each step. The two endpoint checks cover a peak at a boundary. `high` always sits at or after the first valid moment.

**Output.** The chosen moment gives the final tree price.

```nim
  var bestValue = mstAt(bestMoment, edgeFrom, edgeTo, edgeA, edgeB,
                        cityCount, roadCount).total
  if abs(bestMoment) < 0.0005: bestMoment = 0.0
  if abs(bestValue) < 0.0005: bestValue = 0.0
  appendOutput(formatFloat(bestMoment, ffDecimal, 3) & " " &
               formatFloat(bestValue, ffDecimal, 3))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Both numbers print three digits. The near-zero checks remove a negative zero. One buffer flushes every 256 KiB.

## Complexity

Each search step rebuilds one tree from sorted roads.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | one input buffer |
| One slope query | O(m log m + n) | O(m + n) arrays |
| One case | 54 slope queries | O(m + n) arrays |
| Output | O(t) | one output block |

With `m <= 820`, one sort stays cheap.

| Measure | Big O |
| --- | --- |
| Time | O(54 * m log m) per case |
| Space | O(m + n) plus I/O buffers |

A grid search that rebuilds a tree at thousands of moments costs far more tree builds per case.
