# COMPANYS — Two Famous Companies (SPOJ)

<https://www.spoj.com/problems/COMPANYS/>

## Problem

Connect all cities with exactly `K` cables from one company and the rest from the other company, at minimum total cost.

Each test case starts with `N`, `M`, `K`. The next `M` lines give `a`, `b`, `c` and `x`. These are the two cities, the cost and the company number. Zero means the first company and one means the second. Print `Case k: ` and the minimum cost. A valid plan always exists.

| item | bound |
|---|---|
| cities N | 1 to 50000 |
| cable plans M | N-1 to 100000 |
| required first-company cables K | 0 to N-1 |
| cable cost c | 1 to 100 |
| judge limit | 10000 ms, 1536 MB |

The small cost range lets one counting sort serve every search step.

Sample input:

```
2 2 1
0 1 1 1
0 1 2 0
2 2 0
0 1 1 1
0 1 2 0
```

Sample output:

```
Case 1: 2
Case 2: 1
```

## Idea

Give the first company's cables an adjustable discount. Raise it until the cheap tree uses exactly the required count. This is like shifting an exchange rate until a basket has the right mix.

For a discount `lambda`, sort cables by `cost - lambda` for the first company and by `cost` for the second. Kruskal's algorithm then builds the cheapest spanning tree under those adjusted prices. The number of first-company cables in that tree rises as `lambda` rises.

Binary search finds the smallest `lambda` whose tree uses at least `K` first-company cables. At that value the cheapest tree with exactly `K` cables shares the adjusted cost. Add `lambda * K` back to recover its real cost. Each search step merges two pre-sorted lists and runs one union-find pass, so no re-sorting happens.

## Why It Works

1. Kruskal's algorithm builds a minimum spanning tree for any fixed edge prices.
2. Lowering a first-company cable's price by `lambda` cannot make fewer such cables optimal.
3. The chosen count is therefore monotone in `lambda`, which allows binary search.
4. Costs are integers, so the count changes only at integer discount values.
5. At the first `lambda` with count at least `K`, some minimum tree uses exactly `K` cables.
6. That tree's real cost equals its adjusted cost plus `lambda * K`.

| term | meaning |
|---|---|
| `lambdaValue` | discount applied to each first-company cable |
| `telecomOrder` | first-company edge indexes sorted by cost |
| `unicomOrder` | second-company edge indexes sorted by cost |
| `telecomPicked` | first-company cables chosen by one Kruskal pass |
| `adjustedTotal` | sum of adjusted prices in that pass |
| `minimumCost` | adjusted total plus the discount added back |

The table connects the search quantities to their program names.

A script-traced example for the first sample case:

| step | value |
|---|---|
| cables | second company cost 1, first company cost 2 |
| discount 0 | adjusted prices 1 and 2, so the count is 0 |
| discount 1 | adjusted prices 1 and 1, first company goes first on ties |
| chosen count | 1, which meets `K = 1` |
| adjusted total | 1 |
| real cost | `1 + 1 * 1 = 2` |

The trace gives the same answer as the first sample line.

Ties always favour the first company, so the search sees the largest count available at each discount. Adding `lambda * K` back is exact because no rounding appears anywhere in the search.

## Code

**Shared input and output helpers.** The reader loads stdin once and detects the next case by looking for a digit.

```nim
const flushBlockBytes = 1 shl 17
const maxCableCost = 100
const lambdaLowerBound = -1000
const lambdaUpperBound = 1000

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

proc hasMoreTokens(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

proc findRoot(parent: var seq[int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The EOF test allows cases to share lines or occupy separate lines.
Union-find uses path halving to keep each lookup short.
Output stays in one buffer until a block fills.

**Cost ordering.** A counting sort groups each company's cables by cost once per case.

```nim
var edgeFrom = newSeq[int]()
var edgeTo = newSeq[int]()
var edgeCost = newSeq[int]()
var edgeIsTelecom = newSeq[bool]()
var telecomOrder = newSeq[int]()
var unicomOrder = newSeq[int]()
var parent = newSeq[int]()
var caseParent = newSeq[int]()

proc buildCostOrder(isTelecom: bool): seq[int] =
  var bucketCounts = newSeq[int](maxCableCost + 1)
  for edgeIndex in 0 .. edgeCost.len - 1:
    if edgeIsTelecom[edgeIndex] == isTelecom:
      bucketCounts[edgeCost[edgeIndex]] += 1
  var startPositions = newSeq[int](maxCableCost + 2)
  for costValue in 1 .. maxCableCost:
    startPositions[costValue + 1] = startPositions[costValue] + bucketCounts[costValue]
  var resultOrder = newSeq[int](startPositions[maxCableCost + 1])
  var cursors = newSeq[int](maxCableCost + 1)
  for costValue in 1 .. maxCableCost:
    cursors[costValue] = startPositions[costValue]
  for edgeIndex in 0 .. edgeCost.len - 1:
    if edgeIsTelecom[edgeIndex] == isTelecom:
      let costValue = edgeCost[edgeIndex]
      resultOrder[cursors[costValue]] = edgeIndex
      cursors[costValue] += 1
  return resultOrder
```

Costs from 1 to 100 give exactly 101 buckets.
The stable fill keeps original order inside each cost.
Both lists are reused by every discount value.

**Kruskal pass.** Each pass merges the two lists under one discount.

```nim
proc kruskalPass(lambdaValue: int, telecomPicked: var int, adjustedTotal: var int64) =
  for city in 0 .. caseParent.len - 1:
    parent[city] = city
  var telecomPos = 0
  var unicomPos = 0
  telecomPicked = 0
  adjustedTotal = 0
  while telecomPos < telecomOrder.len or unicomPos < unicomOrder.len:
    var takeTelecom = false
    var edgeAdjustedCost = 0
    if telecomPos < telecomOrder.len and unicomPos < unicomOrder.len:
      let telecomAdjusted = edgeCost[telecomOrder[telecomPos]] - lambdaValue
      let unicomAdjusted = edgeCost[unicomOrder[unicomPos]]
      if telecomAdjusted <= unicomAdjusted:
        takeTelecom = true
        edgeAdjustedCost = telecomAdjusted
      else:
        edgeAdjustedCost = unicomAdjusted
    elif telecomPos < telecomOrder.len:
      takeTelecom = true
      edgeAdjustedCost = edgeCost[telecomOrder[telecomPos]] - lambdaValue
    else:
      edgeAdjustedCost = edgeCost[unicomOrder[unicomPos]]
    var edgeIndex = 0
    if takeTelecom:
      edgeIndex = telecomOrder[telecomPos]
      telecomPos += 1
    else:
      edgeIndex = unicomOrder[unicomPos]
      unicomPos += 1
    let firstRoot = findRoot(parent, edgeFrom[edgeIndex])
    let secondRoot = findRoot(parent, edgeTo[edgeIndex])
    if firstRoot != secondRoot:
      parent[firstRoot] = secondRoot
      adjustedTotal = adjustedTotal + int64(edgeAdjustedCost)
      if takeTelecom:
        telecomPicked += 1
```

The merge visits each cable once.
Equal adjusted prices take the first company's cable first.
Skipping a cable that closes a cycle keeps the forest acyclic.

**Case loop.** Binary search finds the discount, then one more pass gives the adjusted total.

```nim
var caseNumber = 1
while hasMoreTokens(inputData, scanPos):
  let cityCount = nextInt(inputData, scanPos)
  let cableCount = nextInt(inputData, scanPos)
  let requiredTelecom = nextInt(inputData, scanPos)
  edgeFrom.setLen(cableCount)
  edgeTo.setLen(cableCount)
  edgeCost.setLen(cableCount)
  edgeIsTelecom.setLen(cableCount)
  for edgeIndex in 0 .. cableCount - 1:
    edgeFrom[edgeIndex] = nextInt(inputData, scanPos)
    edgeTo[edgeIndex] = nextInt(inputData, scanPos)
    edgeCost[edgeIndex] = nextInt(inputData, scanPos)
    edgeIsTelecom[edgeIndex] = nextInt(inputData, scanPos) == 0
  telecomOrder = buildCostOrder(true)
  unicomOrder = buildCostOrder(false)
  caseParent = newSeq[int](cityCount)
  parent = newSeq[int](cityCount)
  var lowLambda = lambdaLowerBound
  var highLambda = lambdaUpperBound
  var pickedCount = 0
  var ignoredTotal: int64 = 0
  while lowLambda < highLambda:
    let middleLambda = lowLambda + (highLambda - lowLambda) div 2
    kruskalPass(middleLambda, pickedCount, ignoredTotal)
    if pickedCount >= requiredTelecom:
      highLambda = middleLambda
    else:
      lowLambda = middleLambda + 1
  var adjustedTotal: int64 = 0
  kruskalPass(lowLambda, pickedCount, adjustedTotal)
  let minimumCost = adjustedTotal + int64(lowLambda) * int64(requiredTelecom)
  appendOutput("Case " & $caseNumber & ": " & $minimumCost & "\n")
  caseNumber += 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

The midpoint uses a positive difference, so negative discounts work.
The search needs about eleven passes over the cable list.
The final pass supplies the adjusted total used by the answer.

## Complexity

Counting sort runs once per case, and each binary-search step is one linear merge over the cables.

| phase | time | space |
|---|---|---|
| counting sort | O(M + 101) | two order arrays |
| discount search | O(M log 2001) per case | union-find arrays |
| output | one buffered write per block | one output string |

The phase table shows that the fixed cost range keeps sorting linear.

| measure | Big O |
|---|---|
| time | O(M log 2001) per case |
| space | O(N + M) |

Sorting from scratch at every discount would add a log M factor to each search step.
