# RETDIG — Return of the Digger (SPOJ)

<https://www.spoj.com/problems/RETDIG/>

## Problem

A digger drops a drill straight down from any surface column. The drill has no brake, so it stops only when it strikes a rock, one metre above that rock, and the bit breaks. The digger can move sideways at no cost after each stop. Find the fewest broken bits needed to collect the treasure and then pass below every rock.

Input gives L and N, then N pairs A and B for rock depth and column, then the treasure depth Y and column X. Print that minimum, or the words “Use dynamite” when no route works.

| item | bound |
|---|---|
| land length L | 1 to 200 |
| rock count N | 1 to 5000 |
| rock and treasure depth | at most 10000 |
| judge limit | 2000 ms, 1536 MB |

The rock count drives the design; a grid over all depths and columns is larger.

Sample input:

```
10 20
1 5
2 1
2 2
2 4
2 5
2 6
2 8
2 9
3 3
4 7
4 8
4 9
5 3
5 4
5 5
5 6
6 3
10 1
10 2
10 7
8 6
```

Sample output:

```
3
```

The path in the statement uses exactly three drill bits.

## Idea

Treat each stop height as a station, like hopping between ledges on a cliff where a sideways walk is free. From a ledge, choose any column and drill to the first rock below; that costs one bit and lands one metre above that rock. Because sideways movement is free, the column of the last rock no longer matters. Only the stop height and whether the treasure is already held matter. Dynamic programming over sorted stop heights costs O(N L log N) per case. A full grid over depths and columns stores far more states. The free sideways walk is the reason the state collapses.

## Why It Works

1. A rock at depth A stops the drill one metre above it, so the new stop height is A - 1.
2. At any stop height the digger can walk to every column, so the last column is irrelevant to future choices.
3. Drilling from depth d in column c reaches the shallowest rock deeper than d in that column, or escapes below all rocks.
4. The treasure is collected by stopping at depth Y, or by drilling past depth Y in column X - 1 or X + 1.
5. Drilling in column X itself stops at or above depth Y; it is invalid only when the first rock lies below Y + 1.
6. Every transition reaches a strictly greater stop height, so the states form a directed acyclic order.

| term | meaning |
|---|---|
| stopDepths | surface plus one metre above every rock |
| columnRocks | sorted rock depths in one column |
| costDirt | fewest bits to reach a height without the treasure |
| costTreasure | fewest bits to reach a height holding the treasure |

The table names the four structures that make the height-only state work.

The generator traces the sample route as follows:

```
surface -> column 7: rock at depth 4, stop at 3, bits 1
depth 3 -> column 5: rock at depth 5, stop at 4, bits 2
depth 4 -> column 7: rock at depth 10, stop at 9, bits 3
treasure at depth 8 is passed in column 7
depth 9 -> column 10: no rock below, finish
```

No further bit breaks are needed after depth 9, so the answer is 3.

A rock one metre below the current height gives no progress, so that transition is skipped.

## Code

**Input and helpers.** The reader loads rocks, and two searches locate the next rock and its height.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const impossibleCost = 1000000000

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

proc ascending(left: int, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

proc firstRockBelow(depths: seq[int], currentDepth: int): int =
  var low = 0
  var high = depths.len
  while low < high:
    let middle = (low + high) div 2
    if depths[middle] <= currentDepth:
      low = middle + 1
    else:
      high = middle
  if low == depths.len:
    return 0
  return depths[low]

proc depthIndex(depths: seq[int], target: int): int =
  var low = 0
  var high = depths.len
  while low < high:
    let middle = (low + high) div 2
    if depths[middle] < target:
      low = middle + 1
    else:
      high = middle
  return low
```

Zero marks the case where no rock lies below.
Both searches use plain binary search on sorted arrays.
Depths and costs fit in signed integers.

**Setup.** Rocks are grouped by column, and stop heights are sorted and made unique.

```nim
let landLength = nextInt(inputData, scanPos)
let rockCount = nextInt(inputData, scanPos)
var columnRocks = newSeq[seq[int]](landLength + 1)
var stopDepths = newSeq[int]()
stopDepths.add 0
for rockIndex in 0 .. rockCount - 1:
  let rockDepth = nextInt(inputData, scanPos)
  let rockColumn = nextInt(inputData, scanPos)
  columnRocks[rockColumn].add rockDepth
  stopDepths.add rockDepth - 1
let treasureDepth = nextInt(inputData, scanPos)
let treasureColumn = nextInt(inputData, scanPos)
for column in 0 .. landLength:
  columnRocks[column].sort(ascending)
stopDepths.sort(ascending)
var uniqueDepths = newSeq[int]()
for depth in stopDepths:
  if uniqueDepths.len == 0 or uniqueDepths[uniqueDepths.len - 1] != depth:
    uniqueDepths.add depth
var costDirt = newSeq[int](uniqueDepths.len)
var costTreasure = newSeq[int](uniqueDepths.len)
for index in 0 .. uniqueDepths.len - 1:
  costDirt[index] = impossibleCost
  costTreasure[index] = impossibleCost
costDirt[0] = 0
```

The surface is stop height zero.
Rock depth A contributes stop height A - 1.
Each height has two cost slots, one per treasure flag.

**Height sweep.** Each height tries every column and applies the treasure rules.

```nim
var bestCost = impossibleCost
for depthIndex in 0 .. uniqueDepths.len - 1:
  let currentDepth = uniqueDepths[depthIndex]
  for carriedTreasure in 0 .. 1:
    let currentCost = if carriedTreasure == 0: costDirt[depthIndex] else: costTreasure[depthIndex]
    if currentCost >= impossibleCost:
      continue
    var activeFlag = carriedTreasure
    if carriedTreasure == 0 and currentDepth == treasureDepth:
      activeFlag = 1
    if activeFlag == 0 and currentDepth > treasureDepth:
      continue
    for column in 0 .. landLength:
      let rockAhead = firstRockBelow(columnRocks[column], currentDepth)
      var nextFlag = activeFlag
      if nextFlag == 0:
        if currentDepth < treasureDepth:
          if column == treasureColumn:
            if rockAhead == 0 or rockAhead > treasureDepth + 1:
              continue
            if rockAhead == treasureDepth + 1:
              nextFlag = 1
          elif column == treasureColumn - 1 or column == treasureColumn + 1:
            if rockAhead == 0 or rockAhead >= treasureDepth + 1:
              nextFlag = 1
        elif currentDepth == treasureDepth:
          nextFlag = 1
        else:
          continue
      if rockAhead == 0:
        if nextFlag == 1 and currentCost < bestCost:
          bestCost = currentCost
      else:
        let nextDepth = rockAhead - 1
        if nextDepth <= currentDepth:
          continue
        let nextIndex = depthIndex(uniqueDepths, nextDepth)
        if nextFlag == 0:
          if currentCost + 1 < costDirt[nextIndex]:
            costDirt[nextIndex] = currentCost + 1
        else:
          if currentCost + 1 < costTreasure[nextIndex]:
            costTreasure[nextIndex] = currentCost + 1
```

Stopping at the treasure depth collects it before any drill.
A column without a lower rock finishes the route at no extra cost.
Transitions that do not gain height are discarded.

**Answer.** One line reports the minimum or the failure phrase.

```nim
if bestCost == impossibleCost:
  appendOutput("Use dynamite")
else:
  appendOutput($bestCost)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The sentinel means no valid route exists.
All other costs are written as plain integers.
The final flush emits the single line.

## Complexity

Sorting and the height-by-column sweep set the cost.

| phase | time | space |
|---|---|---|
| rock grouping | O(N) appends | one list per column |
| sorting | O(N log N) across columns | same lists |
| height sweep | O(N L log N) binary searches | two cost arrays |
| output | one line | block buffer |

The sweep dominates because it visits each height and each column.

| measure | Big O |
|---|---|
| time | O(N L log N) |
| space | O(N + L) |

A full depth-by-column grid would hold about 10000 times 200 states, far more than the N stop heights.

Free sideways movement collapses each stop height into one state.
