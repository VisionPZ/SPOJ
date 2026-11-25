# FRONT — Front (SPOJ)

<https://www.spoj.com/problems/FRONT/>

## Problem

Count the soldiers that sit on the frontline: no other soldier lies at the same or a larger x and the same or a larger y. A soldier disappears from the frontline when another one covers both coordinates.

Input starts with the soldier count. Each later line gives one coordinate pair, and x values arrive in ascending order. No two soldiers share a position.

Output one integer, the number of frontline soldiers.

| item | bound |
|---|---|
| soldiers N | 1 to 1000000 |
| coordinate value | 0 to 1000000000 |
| coordinate pairs | distinct |
| order | x ascending in the input |
| judge limit | 1000 ms, 1536 MB |

The x order lets one right-to-left pass replace a comparison of every pair.

Sample input:

```
6
0 1
1 5
3 5
3 2
4 4
5 1
```

Sample output:

```
3
```

## Idea

Sweep from the right like checking a wall from its far end, and remember the tallest y seen so far. A soldier matters only when its group beats that remembered height, like spotting the last peak on a skyline. Group soldiers with equal x, keep the highest y in each group, and compare that height with the best height to the right. Sorting the pairs first covers input that is not in x order. A pairwise scan would test N squared pairs; the sweep tests each group once.

## Why It Works

1. A soldier is hidden exactly when some soldier to its right has a y at least as large.
2. Equal-x soldiers hide each other except the one with the largest y.
3. That largest y is frontline only if it exceeds the best y from larger x values.
4. Sweeping right to left keeps that best y available in one variable.
5. Sorting by x first makes the sweep valid even for imperfect input order.

| term | meaning |
|---|---|
| `groupX` | x coordinate of the group being processed |
| `groupHeight` | largest y inside that group |
| `bestRightHeight` | largest y among all groups already scanned |
| `frontlineCount` | number of groups that beat the remembered height |

The four rows describe the state carried by the sweep.

A worked example from the generator:

```
x=5 group height 1 -> best -1 -> frontline
x=4 group height 4 -> best 1 -> frontline
x=3 group height 5 -> best 4 -> frontline
x=1 group height 5 -> best 5 -> hidden
x=0 group height 1 -> best 5 -> hidden
total frontline = 3
```

The trace matches the three points listed in the sample explanation.

## Code

**Input and sorting.** The reader loads every pair and sorts only when x order is broken.

```nim
const flushBlockBytes = 1 shl 17

type Soldier = object
  coordX: int
  coordY: int

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

proc comesBefore(leftSoldier: Soldier, rightSoldier: Soldier): bool =
  if leftSoldier.coordX != rightSoldier.coordX:
    return leftSoldier.coordX < rightSoldier.coordX
  return leftSoldier.coordY < rightSoldier.coordY

proc sortSoldiers(values: var seq[Soldier], lowIndex: int, highIndex: int) =
  if highIndex - lowIndex < 16:
    var sortIndex = lowIndex + 1
    while sortIndex <= highIndex:
      let heldSoldier = values[sortIndex]
      var shiftIndex = sortIndex
      while shiftIndex > lowIndex and comesBefore(heldSoldier, values[shiftIndex - 1]):
        values[shiftIndex] = values[shiftIndex - 1]
        shiftIndex -= 1
      values[shiftIndex] = heldSoldier
      sortIndex += 1
    return
  let pivotSoldier = values[(lowIndex + highIndex) div 2]
  var leftIndex = lowIndex
  var rightIndex = highIndex
  while leftIndex <= rightIndex:
    while comesBefore(values[leftIndex], pivotSoldier):
      leftIndex += 1
    while comesBefore(pivotSoldier, values[rightIndex]):
      rightIndex -= 1
    if leftIndex <= rightIndex:
      swap(values[leftIndex], values[rightIndex])
      leftIndex += 1
      rightIndex -= 1
  if lowIndex < rightIndex:
    sortSoldiers(values, lowIndex, rightIndex)
  if leftIndex < highIndex:
    sortSoldiers(values, leftIndex, highIndex)
```

A middle pivot keeps recursion balanced on ordered input.
Insertion sort handles short ranges inside the quicksort.
The sort runs only after an x-order check fails.

**Right-to-left scan.** Each equal-x group contributes at most one frontline soldier.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let soldierCount = nextInt(inputData, scanPos)
var soldiers = newSeq[Soldier](soldierCount)
for soldierIndex in 0 .. soldierCount - 1:
  soldiers[soldierIndex].coordX = nextInt(inputData, scanPos)
  soldiers[soldierIndex].coordY = nextInt(inputData, scanPos)

var needsSorting = false
for soldierIndex in 1 .. soldierCount - 1:
  if soldiers[soldierIndex].coordX < soldiers[soldierIndex - 1].coordX:
    needsSorting = true
    break
if needsSorting:
  sortSoldiers(soldiers, 0, soldierCount - 1)

var frontlineCount = 0
var bestRightHeight = -1
var scanIndex = soldierCount - 1
while scanIndex >= 0:
  let groupX = soldiers[scanIndex].coordX
  var groupHeight = -1
  while scanIndex >= 0 and soldiers[scanIndex].coordX == groupX:
    if soldiers[scanIndex].coordY > groupHeight:
      groupHeight = soldiers[scanIndex].coordY
    scanIndex -= 1
  if groupHeight > bestRightHeight:
    frontlineCount += 1
    bestRightHeight = groupHeight

appendOutput($frontlineCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The inner loop consumes a whole equal-x group at once.
The height comparison uses strict inequality, so ties hide the left soldier.
One number is written after the sweep ends.

## Complexity

The scan visits each soldier once, and the fallback sort runs only for unordered input.

| phase | time | space |
|---|---|---|
| input read | one pass over the coordinate list | one input string |
| order check | one pass over x values | constant |
| fallback sort | n log n comparisons when needed | constant auxiliary |
| sweep | one pass from right to left | one pair array |
| output | one line | block buffer |

Ordered input skips the sort and stays linear.

| measure | Big O |
|---|---|
| time | O(N) on sorted input, O(N log N) otherwise |
| space | O(N) for the coordinate pairs |

Checking every pair would cost O(N squared), which is too large for a million soldiers.
The sweep keeps only the best height to the right of each group.
