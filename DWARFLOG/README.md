<https://www.spoj.com/problems/DWARFLOG/>

## Problem

Dwarves of heights one through N start in sorted order. Each request either swaps two heights in the line or asks whether a height interval occupies one contiguous block of positions. Answer each query with YES or NO.

| item | bound |
|---|---|
| dwarves N | 2 to 200000 |
| requests M | 2 to 200000 |
| swap heights X, Y | distinct values in 1 to N |
| judge limit | 1000 ms, 1536 MB |

The order of heights inside the queried block does not matter.

Sample input:

```
4 5
2 2 3
2 2 4
1 1 3
2 3 4
1 4 3
```

Sample output:

```
YES
YES
NO
```

## Idea

A set of heights forms one block exactly when its leftmost and rightmost positions are as close as the count allows. Think of numbered books on a shelf: if the first and last book of a series sit the right number of slots apart, no other book interrupts the series. A segment tree tracks the minimum and maximum position for each height interval after every swap.

## Why It Works

1. The query covers B minus A plus one distinct heights.
2. Those heights occupy exactly that many distinct positions.
3. Their positions are consecutive when the largest minus the smallest equals the count minus one.
4. A swap changes two stored positions and nothing else.
5. A segment tree answers each range extreme query in logarithmic time.

| term | meaning |
|---|---|
| `heightPositions` | current line position of each height |
| `minimumTree` | segment tree of smallest positions |
| `maximumTree` | segment tree of largest positions |
| `baseSize` | power of two covering all heights |

Both trees share one iterative layout with leaves at offsets from the base size.

## Code

**Input and tree construction.** The reader loads the request stream and builds two iterative segment trees.

```nim
const flushBlockBytes = 1 shl 17
const missingValue = 1000000007

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let dwarfCount = nextInt(inputData, scanPos)
let requestCount = nextInt(inputData, scanPos)

var baseSize = 1
while baseSize < dwarfCount:
  baseSize = baseSize * 2

var minimumTree = newSeq[int](2 * baseSize)
var maximumTree = newSeq[int](2 * baseSize)
for leafIndex in 0 .. baseSize - 1:
  minimumTree[baseSize + leafIndex] = missingValue
  maximumTree[baseSize + leafIndex] = 0

var heightPositions = newSeq[int](dwarfCount)
for heightIndex in 0 .. dwarfCount - 1:
  heightPositions[heightIndex] = heightIndex + 1
  minimumTree[baseSize + heightIndex] = heightIndex + 1
  maximumTree[baseSize + heightIndex] = heightIndex + 1

for treeIndex in countdown(baseSize - 1, 1):
  minimumTree[treeIndex] = min(minimumTree[2 * treeIndex], minimumTree[2 * treeIndex + 1])
  maximumTree[treeIndex] = max(maximumTree[2 * treeIndex], maximumTree[2 * treeIndex + 1])
```

Unused leaves hold a value beyond every real position.
The initial line is sorted, so each height starts at its own index plus one.
Parent nodes combine the two children after the leaves are filled.

**Point updates and range queries.** Two leaf changes handle a swap, and two tree walks handle a query.

```nim
proc updateHeight(heightIndex: int, positionValue: int) =
  var treeIndex = baseSize + heightIndex
  minimumTree[treeIndex] = positionValue
  maximumTree[treeIndex] = positionValue
  treeIndex = treeIndex div 2
  while treeIndex >= 1:
    minimumTree[treeIndex] = min(minimumTree[2 * treeIndex], minimumTree[2 * treeIndex + 1])
    maximumTree[treeIndex] = max(maximumTree[2 * treeIndex], maximumTree[2 * treeIndex + 1])
    treeIndex = treeIndex div 2

proc rangeMinimum(leftHeight: int, rightHeight: int): int =
  var leftIndex = baseSize + leftHeight
  var rightIndex = baseSize + rightHeight
  var bestValue = missingValue
  while leftIndex <= rightIndex:
    if (leftIndex mod 2) == 1:
      bestValue = min(bestValue, minimumTree[leftIndex])
      leftIndex += 1
    if (rightIndex mod 2) == 0:
      bestValue = min(bestValue, minimumTree[rightIndex])
      rightIndex -= 1
    leftIndex = leftIndex div 2
    rightIndex = rightIndex div 2
  return bestValue
```

Each updated leaf recomputes only its ancestor chain.
Odd left boundaries and even right boundaries are consumed directly.
Every query touches at most two nodes per tree level.

**Maximum query and driver.** The largest position completes the contiguity test.

```nim
proc rangeMaximum(leftHeight: int, rightHeight: int): int =
  var leftIndex = baseSize + leftHeight
  var rightIndex = baseSize + rightHeight
  var bestValue = 0
  while leftIndex <= rightIndex:
    if (leftIndex mod 2) == 1:
      bestValue = max(bestValue, maximumTree[leftIndex])
      leftIndex += 1
    if (rightIndex mod 2) == 0:
      bestValue = max(bestValue, maximumTree[rightIndex])
      rightIndex -= 1
    leftIndex = leftIndex div 2
    rightIndex = rightIndex div 2
  return bestValue

for requestIndex in 0 .. requestCount - 1:
  let requestType = nextInt(inputData, scanPos)
  let firstValue = nextInt(inputData, scanPos)
  let secondValue = nextInt(inputData, scanPos)
  if requestType == 1:
    let firstHeight = firstValue - 1
    let secondHeight = secondValue - 1
    let firstPosition = heightPositions[firstHeight]
    let secondPosition = heightPositions[secondHeight]
    heightPositions[firstHeight] = secondPosition
    heightPositions[secondHeight] = firstPosition
    updateHeight(firstHeight, secondPosition)
    updateHeight(secondHeight, firstPosition)
  else:
    let leftHeight = firstValue - 1
    let rightHeight = secondValue - 1
    let smallestPosition = rangeMinimum(leftHeight, rightHeight)
    let largestPosition = rangeMaximum(leftHeight, rightHeight)
    if largestPosition - smallestPosition == rightHeight - leftHeight:
      appendOutput("YES\n")
    else:
      appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The swap updates both height positions before touching the trees.
A query compares the position span with the height span.
Answers accumulate in one write buffer.

## Complexity

Tree construction uses a power-of-two base larger than the dwarf count.

| phase | time | space |
|---|---|---|
| input read | one pass over all requests | one input string |
| tree build | one pass over the base size | two segment trees |
| swap | two point updates | ancestor chains |
| query | two range walks | constant |
| output | one line per query | block buffer |

| measure | Big O |
|---|---|
| time | O(M log N) |
| space | O(N) |

Scanning every position in the queried interval would cost O(N) per query.
