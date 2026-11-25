# IITWPC4F — Gopu and the Grid Problem (SPOJ)

<https://www.spoj.com/problems/IITWPC4F/>

## Problem

Track lamp states on a 100001 by 100001 grid under row and column flips, then answer rectangle counts. Flipping a column toggles every lamp in that column, and flipping a row toggles every lamp in that row.

Input starts with Q, followed by Q query lines. A line "x l r" flips columns l through r. A line "y l r" flips rows l through r. A line "q x y X Y" asks how many lamps are lit in that rectangle, endpoints included. Print one integer per type-3 query.

| item | bound |
|---|---|
| queries Q | at most 100000 |
| coordinates | 0 to 100000 |
| judge limit | 1000 ms, 1536 MB |

Rectangle answers depend only on the number of flipped-flipped and flipped-unflipped coordinate pairs.

Sample input:

```
3
x 0 1
y 1 2
q 0 0 2 2
```

Sample output:

```
4
```

## Idea

Count flipped columns and rows separately, like counting lit seats by adding lit rows and lit columns without visiting each seat. A lamp is on when exactly one of its coordinates has been flipped an odd number of times.

The algorithm uses two lazy segment trees, one for columns and one for rows. Each range flip costs O(log C), and each rectangle query costs two range sums. Visiting every lamp in a rectangle would cost up to 10^10 checks for the largest grid. The parity product then gives the count in constant time.

Two one-dimensional trees replace a quadrillion possible lamp visits.

## Why It Works

1. Each lamp state equals the xor of its column flip parity and its row flip parity.
2. A flip range applies to one dimension only, so columns and rows stay independent.
3. In a rectangle, on lamps are on-columns paired with off-rows, plus off-columns paired with on-rows.
4. A lazy segment tree stores the number of on positions in each interval and defers flips to children.
5. A full-cover flip changes a node count to the interval length minus the count.

| term | meaning |
|---|---|
| `onCounts` | number of on coordinates stored at a node |
| `pendingFlips` | deferred flip flag for a node |
| `columnsOn` | on columns inside the queried x range |
| `lampsOn` | final rectangle count |

Each term corresponds to a field or local variable in the code.

The worked trace uses the sample:

```
x 0 1: columns 0 and 1 have odd parity
y 1 2: rows 1 and 2 have odd parity
rectangle x 0..2 gives columnsOn = 2, columnsOff = 1
rectangle y 0..2 gives rowsOn = 2, rowsOff = 1
on lamps = 2 * 1 + 1 * 2 = 4
```

The trace yields 4, matching the sample output.

Lazy flags are pushed down only before partial covers, so full-range flips stay cheap.

## Code

**Input, scanners and tree operations.** The reader loads all query lines, then two lazy trees handle parity counts.

```nim
const flushBlockBytes = 1 shl 17
const coordinateLimit = 100000
const treeCapacity = 4 * (coordinateLimit + 1) + 5

type FlipTree = object
  onCounts: array[treeCapacity, int]
  pendingFlips: array[treeCapacity, bool]

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

proc skipSpaces(data: string, pos: var int) =
  while pos < data.len and data[pos] <= ' ':
    pos += 1

proc applyFlip(tree: var FlipTree, nodeIndex: int, leftEdge: int, rightEdge: int) =
  tree.onCounts[nodeIndex] = (rightEdge - leftEdge + 1) - tree.onCounts[nodeIndex]
  tree.pendingFlips[nodeIndex] = not tree.pendingFlips[nodeIndex]

proc pushDown(tree: var FlipTree, nodeIndex: int, leftEdge: int, rightEdge: int) =
  if tree.pendingFlips[nodeIndex] and leftEdge < rightEdge:
    let middle = (leftEdge + rightEdge) div 2
    applyFlip(tree, nodeIndex * 2, leftEdge, middle)
    applyFlip(tree, nodeIndex * 2 + 1, middle + 1, rightEdge)
    tree.pendingFlips[nodeIndex] = false

proc flipRange(tree: var FlipTree, nodeIndex: int, leftEdge: int, rightEdge: int,
               queryLeft: int, queryRight: int) =
  if queryLeft <= leftEdge and rightEdge <= queryRight:
    applyFlip(tree, nodeIndex, leftEdge, rightEdge)
    return
  pushDown(tree, nodeIndex, leftEdge, rightEdge)
  let middle = (leftEdge + rightEdge) div 2
  if queryLeft <= middle:
    flipRange(tree, nodeIndex * 2, leftEdge, middle, queryLeft, queryRight)
  if queryRight > middle:
    flipRange(tree, nodeIndex * 2 + 1, middle + 1, rightEdge, queryLeft, queryRight)
  tree.onCounts[nodeIndex] = tree.onCounts[nodeIndex * 2] + tree.onCounts[nodeIndex * 2 + 1]

proc queryRange(tree: var FlipTree, nodeIndex: int, leftEdge: int, rightEdge: int,
                queryLeft: int, queryRight: int): int =
  if queryLeft <= leftEdge and rightEdge <= queryRight:
    return tree.onCounts[nodeIndex]
  pushDown(tree, nodeIndex, leftEdge, rightEdge)
  let middle = (leftEdge + rightEdge) div 2
  var total = 0
  if queryLeft <= middle:
    total += queryRange(tree, nodeIndex * 2, leftEdge, middle, queryLeft, queryRight)
  if queryRight > middle:
    total += queryRange(tree, nodeIndex * 2 + 1, middle + 1, rightEdge, queryLeft, queryRight)
  return total
```

The tree spans coordinates 0 through `coordinateLimit`.
Each node stores a count and one pending flip bit.
Both updates and queries recurse only into overlapping children.

**Query dispatch.** Each input query updates one tree or combines two range sums.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var columnTree: FlipTree
var rowTree: FlipTree

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  skipSpaces(inputData, scanPos)
  let queryKind = inputData[scanPos]
  if queryKind == 'x':
    let lowerBound = nextInt(inputData, scanPos)
    let upperBound = nextInt(inputData, scanPos)
    flipRange(columnTree, 1, 0, coordinateLimit, lowerBound, upperBound)
  elif queryKind == 'y':
    let lowerBound = nextInt(inputData, scanPos)
    let upperBound = nextInt(inputData, scanPos)
    flipRange(rowTree, 1, 0, coordinateLimit, lowerBound, upperBound)
  else:
    let xLower = nextInt(inputData, scanPos)
    let yLower = nextInt(inputData, scanPos)
    let xUpper = nextInt(inputData, scanPos)
    let yUpper = nextInt(inputData, scanPos)
    let columnsOn = queryRange(columnTree, 1, 0, coordinateLimit, xLower, xUpper)
    let rowsOn = queryRange(rowTree, 1, 0, coordinateLimit, yLower, yUpper)
    let columnsOff = (xUpper - xLower + 1) - columnsOn
    let rowsOff = (yUpper - yLower + 1) - rowsOn
    let lampsOn = int64(columnsOn) * int64(rowsOff) + int64(columnsOff) * int64(rowsOn)
    appendOutput($lampsOn)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The kind letter is read before the numeric scanner.
Products use int64 to hold the full grid area.
Buffered writes flush once after all queries.

## Complexity

Each query touches only logarithmically many tree nodes.

| phase | time | space |
|---|---|---|
| input read | one pass over Q query lines | one input string |
| flips | O(log C) per flip query | two node arrays |
| rectangle counts | two O(log C) range sums | block buffer |
| output | one buffered line per query | block buffer |

Tree work dominates, and both dimensions use the same tree height.

| measure | Big O |
|---|---|
| time | O(Q log C) with C = 100001 |
| space | O(C) for two lazy trees |

Scanning each lamp in a rectangle would cost up to 10^10 operations, while two range sums settle it in logarithmic time.
