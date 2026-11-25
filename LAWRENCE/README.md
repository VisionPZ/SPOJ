# LAWRENCE — Lawrence of Arabia (SPOJ)

<https://www.spoj.com/problems/LAWRENCE/>

## Problem

Cut a line of outposts at up to N places so that the sum of pairwise products inside every remaining group is as small as possible. Each cut splits the line into one more contiguous group.

The input has three lines: the outpost count P, the attack count N, and P values from 0 to 20. Print the minimum total strategic value after all attacks.

| item | bound |
|---|---|
| outposts P | between 1 and 500 |
| attacks N | between 0 and P-1 |
| outpost value | between 0 and 20 |
| judge limit | 1000 ms, 1536 MB |

The groups stay in line order; an attack never reorders outposts.

The sample input:

```
4
1
4 5 1 2
```

The sample output:

```
17
```

## Idea

Give each group boundary a cost and let a hull pick the cheapest boundary for every endpoint. This resembles picking the shortest route to each station by keeping only the bus lines that can win.

For a group, the pairwise sum equals (sum squared minus sum of squares) divided by two. Expanding that formula turns one DP row into a set of lines queried at prefix sums. Since prefix sums never decrease, a deque hull answers each query in amortized constant time. A plain DP would try every boundary for every endpoint and cost O(N times P squared).

The hull keeps one DP row at constant amortized cost per endpoint.

## Why It Works

1. Destroying N segments creates N+1 nonempty contiguous groups.
2. A group from l to r has pairwise sum (S squared minus Q) over two, where S is the group sum and Q is the sum of squares.
3. For a fixed endpoint, the DP choice becomes a line with slope minus two times an earlier prefix sum.
4. The query position is the current prefix sum, which never decreases as the endpoint moves right.
5. Lines enter with nonincreasing slopes, so a deque removes obsolete lines once and keeps the minimum value at each query.

| term | meaning |
|---|---|
| `prefixSum` | running sum of outpost values |
| `prefixSquares` | running sum of squared outpost values |
| `HullLine` | one candidate boundary written as slope and intercept |
| `previousCosts` | best cost row for the smaller group count |
| `isObsolete` | test that removes a line that can never win |

Equal slopes keep only the line with the smaller intercept.

A script trace for the sample with one attack:

```
cut after left right total
1 0 17 17
2 20 2 22
3 29 0 29
```

The smallest total is 17, matching the sample output.

## Code

**Input, hull helpers, and prefixes.** The reader builds prefix sums and the line helpers stay generic.

```nim
const flushBlockBytes = 1 shl 17

type HullLine = object
  slope: int64
  intercept: int64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc lineValue(line: HullLine, position: int64): int64 =
  return line.slope * position + line.intercept

proc isObsolete(firstLine, middleLine, lastLine: HullLine): bool =
  let leftSide = (middleLine.intercept - firstLine.intercept) *
      (middleLine.slope - lastLine.slope)
  let rightSide = (lastLine.intercept - middleLine.intercept) *
      (firstLine.slope - middleLine.slope)
  return leftSide >= rightSide

proc addLine(hull: var seq[HullLine], head: var int, slope: int64, intercept: int64) =
  if hull.len > head and hull[hull.len - 1].slope == slope:
    if intercept < hull[hull.len - 1].intercept:
      hull[hull.len - 1].intercept = intercept
    return
  hull.add(HullLine(slope: slope, intercept: intercept))
  while hull.len - head >= 3 and isObsolete(hull[hull.len - 3],
      hull[hull.len - 2], hull[hull.len - 1]):
    hull[hull.len - 2] = hull[hull.len - 1]
    hull.setLen(hull.len - 1)

proc query(hull: seq[HullLine], head: var int, position: int64): int64 =
  while head + 1 < hull.len and lineValue(hull[head], position) >=
      lineValue(hull[head + 1], position):
    head += 1
  return lineValue(hull[head], position)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let outpostCount = nextInt(inputData, scanPos)
let attackCount = nextInt(inputData, scanPos)
var prefixSum = newSeq[int64](outpostCount + 1)
var prefixSquares = newSeq[int64](outpostCount + 1)
for outpostIndex in 0 .. outpostCount - 1:
  let outpostValue = int64(nextInt(inputData, scanPos))
  prefixSum[outpostIndex + 1] = prefixSum[outpostIndex] + outpostValue
  prefixSquares[outpostIndex + 1] = prefixSquares[outpostIndex] +
      outpostValue * outpostValue
```

All prefix values are int64, so squared sums stay exact.
`isObsolete` uses cross multiplication instead of division.
The deque head advances only forward, once per query step.

**Group-count DP.** Each new row adds one line per endpoint and queries the cheapest boundary.

```nim
var previousCosts = newSeq[int64](outpostCount + 1)
for filledCount in 1 .. outpostCount:
  let total = prefixSum[filledCount]
  previousCosts[filledCount] = (total * total - prefixSquares[filledCount]) div 2

let groupCount = attackCount + 1
if groupCount >= 2:
  for currentGroups in 2 .. groupCount:
    var currentCosts = newSeq[int64](outpostCount + 1)
    var hull = newSeq[HullLine]()
    var head = 0
    for filledCount in currentGroups .. outpostCount:
      let split = filledCount - 1
      let splitTotal = prefixSum[split]
      let slope = -2 * splitTotal
      let intercept = 2 * previousCosts[split] + splitTotal * splitTotal +
          prefixSquares[split]
      addLine(hull, head, slope, intercept)
      let position = prefixSum[filledCount]
      let bestLine = query(hull, head, position)
      let total = prefixSum[filledCount]
      currentCosts[filledCount] = (total * total - prefixSquares[filledCount] +
          bestLine) div 2
    previousCosts = currentCosts

appendOutput($previousCosts[outpostCount])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first row holds the cost of one group.
Each later row keeps boundaries only for feasible splits.
The final row at P holds the minimum after N attacks.

## Complexity

Each group-count row adds and queries one line per endpoint.

| phase | time | space |
|---|---|---|
| input read | one pass over P values | input string |
| prefixes | one pass over P values | two arrays of P entries |
| DP rows | one hull query per endpoint and row | one hull and two rows |
| output | one line | block buffer |

The DP dominates, and the hull removes the quadratic boundary loop.

| measure | Big O |
|---|---|
| time | O(N times P) |
| space | O(P) |

A plain DP tests every boundary for every endpoint and grows as O(N times P squared).
