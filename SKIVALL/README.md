# SKIVALL — Ski Valley (SPOJ)

<https://www.spoj.com/problems/SKIVALL/>

## Problem

Find the longest path on a height grid that goes strictly downhill, reaches one lowest cell, then goes strictly uphill. Cells may not repeat, and neighbouring cells share an edge.

Input starts with `M N`, followed by M rows of N heights. All heights are distinct and may be negative.

Output the maximum length, then one coordinate per cell on a valley of that length. Rows and columns are 1-based.

| item | bound |
|---|---|
| rows M | 1 to 60 |
| columns N | 1 to 60 |
| height | -1000000 to 1000000 |
| judge limit | 3817 ms, 1536 MB |

The distinct heights make every strict climb or descent acyclic.

Sample input:

```
3 4
2 6 7 16
1 4 3 20
9 8 17 12
```

Sample output:

```
9
3 1
3 2
2 2
2 1
1 1
1 2
1 3
1 4
2 4
```

## Idea

A valley has two high ends and one low centre, like two streams running down opposite slopes into the same basin. Build the path backwards from those two high ends, always stepping to a lower neighbour.

The algorithm is dynamic programming over pairs of current endpoints. A state holds two cells and the longest partial valley ending there. Each step lowers one endpoint and reuses a smaller state.

Trying every simple path would explode with grid size. The height order makes each step acyclic, so one table of endpoint pairs suffices.

## Why It Works

1. Sort all cells by height and give each a rank.
2. A downhill neighbour always has a smaller rank.
3. A state with endpoints `firstRank` and `secondRank` tracks the best valley seen so far.
4. Moving the higher endpoint down to a neighbour extends that state by one cell.
5. The two branches meet when both ranks are equal, which is the valley centre.
6. Reversing a valid valley gives another valid valley of the same length.
7. The output is flipped when its first cell is taller than its last cell.

| term | meaning |
|---|---|
| `heightRank` | position of a cell in ascending height order |
| `downhillNeighbors` | neighbours with lower height, stored by rank |
| `valleyLengths` | best length for each ordered pair of ranks |
| `predecessors` | previous higher endpoint used to reach a state |
| `valleyPath` | reconstructed cells in output order |

A worked example for the 3 by 3 grid:

```
0 6 5
8 7 2
3 1 4
best length 6
path: (3,3) h4 -> (2,3) h2 -> (1,3) h5 -> (1,2) h6 -> (2,2) h7 -> (2,1) h8
```

The heights descend to 2 and then climb to 8, so the path is a valley.

## Code

**Input and negative parsing.** Heights can be negative, so the scanner keeps a sign.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const impossibleLength = -1000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips separators and optional minus signs.
The buffer handles the whole coordinate list in blocks.
No token strings are allocated during parsing.

**Height ranks and downhill edges.** Every directed edge goes from higher to lower rank.

```nim
let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
let cellCount = rowCount * columnCount
var heights = newSeq[int](cellCount)
for cellIndex in 0 .. cellCount - 1:
  heights[cellIndex] = nextInt(inputData, scanPos)

var orderedCells = newSeq[int](cellCount)
for cellIndex in 0 .. cellCount - 1:
  orderedCells[cellIndex] = cellIndex
orderedCells.sort(proc(leftCell, rightCell: int): int =
  if heights[leftCell] < heights[rightCell]: -1
  elif heights[leftCell] > heights[rightCell]: 1
  else: 0)

var heightRank = newSeq[int](cellCount)
for rankIndex in 0 .. cellCount - 1:
  heightRank[orderedCells[rankIndex]] = rankIndex

var downhillNeighbors = newSeq[seq[int]](cellCount)
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    let cellIndex = rowIndex * columnCount + columnIndex
    for directionIndex in 0 .. 3:
      var neighborRow = rowIndex
      var neighborColumn = columnIndex
      if directionIndex == 0:
        neighborRow += 1
      elif directionIndex == 1:
        neighborColumn += 1
      elif directionIndex == 2:
        neighborRow -= 1
      else:
        neighborColumn -= 1
      if neighborRow < 0 or neighborRow >= rowCount or
         neighborColumn < 0 or neighborColumn >= columnCount:
        continue
      let neighborIndex = neighborRow * columnCount + neighborColumn
      if heights[neighborIndex] < heights[cellIndex]:
        downhillNeighbors[heightRank[cellIndex]].add(heightRank[neighborIndex])
```

Sorting uses an explicit comparator for both compilers.
Each grid edge contributes at most one downhill neighbour.
Ranks turn height comparisons into integer comparisons.

**Endpoint-pair DP.** Each transition lowers one of the two high endpoints.

```nim
var valleyLengths = newSeq[int](cellCount * cellCount)
var predecessors = newSeq[int](cellCount * cellCount)
for stateIndex in 0 .. cellCount * cellCount - 1:
  valleyLengths[stateIndex] = impossibleLength
  predecessors[stateIndex] = 0

var bestLength = 1
var bestFirstRank = 0
var bestSecondRank = 0

for firstRank in 0 .. cellCount - 1:
  valleyLengths[firstRank * cellCount + firstRank] = 1
  for secondRank in firstRank + 1 .. cellCount - 1:
    for lowerRank in downhillNeighbors[secondRank]:
      var leftRank = firstRank
      var rightRank = lowerRank
      if leftRank > rightRank:
        swap(leftRank, rightRank)
      let candidate = 1 + valleyLengths[leftRank * cellCount + rightRank]
      if candidate > valleyLengths[firstRank * cellCount + secondRank]:
        valleyLengths[firstRank * cellCount + secondRank] = candidate
        predecessors[firstRank * cellCount + secondRank] = lowerRank
        if candidate > bestLength:
          bestLength = candidate
          bestFirstRank = firstRank
          bestSecondRank = secondRank
```

Only states with two different ranks are extended.
The smaller rank always indexes the first matrix coordinate.
A strict improvement records the predecessor for reconstruction.

**Reconstruction and output.** The two branches are joined and put in a fixed orientation.

```nim
var firstBranch = newSeq[int]()
var secondBranch = newSeq[int]()
firstBranch.add(orderedCells[bestFirstRank])
secondBranch.add(orderedCells[bestSecondRank])
var leftRank = bestFirstRank
var rightRank = bestSecondRank
while leftRank != rightRank:
  if leftRank > rightRank:
    swap(leftRank, rightRank)
    swap(firstBranch, secondBranch)
  rightRank = predecessors[leftRank * cellCount + rightRank]
  secondBranch.add(orderedCells[rightRank])

var valleyPath = newSeq[int]()
for cellIndex in firstBranch:
  valleyPath.add cellIndex
var reverseIndex = secondBranch.len - 2
while reverseIndex >= 0:
  valleyPath.add secondBranch[reverseIndex]
  reverseIndex -= 1
if heights[valleyPath[0]] > heights[valleyPath[valleyPath.len - 1]]:
  var reversedPath = newSeq[int]()
  reverseIndex = valleyPath.len - 1
  while reverseIndex >= 0:
    reversedPath.add valleyPath[reverseIndex]
    reverseIndex -= 1
  valleyPath = reversedPath

appendOutput($bestLength)
outputBuffer.add '\n'
for cellIndex in valleyPath:
  appendOutput($(cellIndex div columnCount + 1))
  appendOutput(" ")
  appendOutput($(cellIndex mod columnCount + 1))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Predecessor links stop when both branches meet.
The shared centre is printed once.
The final flip makes the answer independent of branch order.

## Complexity

The state space holds one entry per pair of cells.

| phase | time | space |
|---|---|---|
| input read | one pass over cell heights | one input string |
| sorting | one sort of all cells | rank arrays |
| DP | up to four transitions per state | two square tables |
| reconstruction | one walk from endpoints to centre | two branch lists |
| output | one line per cell | block buffer |

Each state updates at most four lower neighbours, so the table size controls runtime.

| measure | Big O |
|---|---|
| time | O(C^2) for C cells |
| space | O(C^2) |

Checking every simple path would be exponential, while the height order gives one acyclic DP pass.
