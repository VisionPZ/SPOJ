# FILTER — Median Filter (SPOJ)

<https://www.spoj.com/problems/FILTER/>

## Problem

Recover the range of possible black-pixel counts from a filtered black-and-white image. The filter replaces each pixel by the majority of its `3x3` window, and edge pixels repeat the nearest real pixel. Report the largest count minus the smallest count, or `Impossible`.

Each case gives `W H`, then `H` lines of `W` characters chosen from `#` and `.`. A line `0 0` ends the input. Print `Case X: difference`.

| item | bound |
|---|---|
| width W | 1 to 8 |
| height H | 1 to 8 |
| cases | until the `0 0` line |
| judge limit | 3567 ms, 1536 MB |

The small image size makes row-by-row enumeration practical.

Sample input:

```
5 5
#####
#####
#####
#####
#####
4 4
####
####
####
####
4 4
#...
....
....
...#
4 4
.#.#
#.#.
.#.#
#.#.
0 0
```

Sample output:

```
Case 1: 10
Case 2: 6
Case 3: 2
Case 4: Impossible
```

## Idea

walk possible original rows as states, like selecting tiles one row at a time. Each state holds the last two rows, because the filter output for a row depends on its neighbour rows. Keep the smallest and largest black count reaching every state. Take dynamic programming over row pairs as the engine.

## Why It Works

1. A filtered pixel is black when at least five of its nine window cells are black.
2. Repeated edge pixels make the window depend only on the three nearby rows.
3. Knowing rows `r-1` and `r` lets us test row `r` once row `r+1` is chosen.
4. A state holds two rows, so there are at most `2^(2W)` states.
5. Minimum and maximum costs update independently along each transition.

| term | meaning |
|---|---|
| `filteredRows` | given image encoded as one bitmask per row |
| `minimumCost` | fewest black pixels reaching a row-pair state |
| `maximumCost` | most black pixels reaching a row-pair state |
| `TripleTable` | triples of rows grouped by filtered result |

A brute trace over the third sample image finds `59` valid originals. Their black counts run from `4` to `6`, giving difference `2`.

## Code

**Reader and bit counts.** The scanner reads image lines as bitmasks.

```nim
const flushBlockBytes = 1 shl 17

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

proc nextImageRow(data: string, pos: var int, widthValue: int): int =
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r' or data[pos] == ' ' or data[pos] == '\t'):
    pos += 1
  var rowMask = 0
  for columnIndex in 0 .. widthValue - 1:
    if pos < data.len and data[pos] == '#':
      rowMask = rowMask or (1 shl columnIndex)
    pos += 1
  return rowMask

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var popcountValues = newSeq[int](256)
for valueIndex in 0 .. 255:
  var remaining = valueIndex
  var countBits = 0
  while remaining > 0:
    countBits += remaining and 1
    remaining = remaining div 2
  popcountValues[valueIndex] = countBits
```

Each image row becomes one bitmask.
Column bits follow the character order in the line.
Black counts come from a precomputed byte table.

**Triple table.** Every triple of rows is grouped by its filtered middle row.

```nim
type TripleTable = object
  starts: seq[int]
  bases: seq[uint16]
  followers: seq[uint8]
  columnCounts: seq[seq[int]]

var tableCache = newSeq[TripleTable](9)

proc buildTable(widthValue: int): TripleTable =
  let rowValues = 1 shl widthValue
  var counts = newSeq[int](rowValues)
  var columnCounts = newSeq[seq[int]](rowValues)
  for rowValue in 0 .. rowValues - 1:
    columnCounts[rowValue] = newSeq[int](widthValue)
    for columnIndex in 0 .. widthValue - 1:
      let leftColumn = if columnIndex > 0: columnIndex - 1 else: 0
      let rightColumn = if columnIndex + 1 < widthValue: columnIndex + 1 else: widthValue - 1
      columnCounts[rowValue][columnIndex] = ((rowValue shr leftColumn) and 1) + ((rowValue shr columnIndex) and 1) + ((rowValue shr rightColumn) and 1)
  for upperRow in 0 .. rowValues - 1:
    for middleRow in 0 .. rowValues - 1:
      for lowerRow in 0 .. rowValues - 1:
        var filteredRow = 0
        for columnIndex in 0 .. widthValue - 1:
          let totalCount = columnCounts[upperRow][columnIndex] + columnCounts[middleRow][columnIndex] + columnCounts[lowerRow][columnIndex]
          if totalCount >= 5:
            filteredRow = filteredRow or (1 shl columnIndex)
        counts[filteredRow] += 1
  var starts = newSeq[int](rowValues + 1)
  for valueIndex in 0 .. rowValues - 1:
    starts[valueIndex + 1] = starts[valueIndex] + counts[valueIndex]
  var cursors = newSeq[int](rowValues)
  for valueIndex in 0 .. rowValues - 1:
    cursors[valueIndex] = starts[valueIndex]
  var bases = newSeq[uint16](starts[rowValues])
  var followers = newSeq[uint8](starts[rowValues])
  for upperRow in 0 .. rowValues - 1:
    for middleRow in 0 .. rowValues - 1:
      let baseIndex = upperRow * rowValues + middleRow
      for lowerRow in 0 .. rowValues - 1:
        var filteredRow = 0
        for columnIndex in 0 .. widthValue - 1:
          let totalCount = columnCounts[upperRow][columnIndex] + columnCounts[middleRow][columnIndex] + columnCounts[lowerRow][columnIndex]
          if totalCount >= 5:
            filteredRow = filteredRow or (1 shl columnIndex)
        let writeAt = cursors[filteredRow]
        bases[writeAt] = uint16(baseIndex)
        followers[writeAt] = uint8(lowerRow)
        cursors[filteredRow] += 1
  return TripleTable(starts: starts, bases: bases, followers: followers, columnCounts: columnCounts)
```

Column counts include the duplicated edge cells.
A counting sort groups each triple by its result.
One table per width serves all later cases.

**Row-pair DP.** States keep two recent rows and two extreme costs.

```nim
proc solveImage(widthValue: int, heightValue: int, filteredRows: seq[int]): string =
  let rowValues = 1 shl widthValue
  if tableCache[widthValue].starts.len == 0:
    tableCache[widthValue] = buildTable(widthValue)
  let table = tableCache[widthValue]
  const unreachable = -1
  if heightValue == 1:
    var bestMin = 1 shl 29
    var bestMax = -1
    for entryIndex in table.starts[filteredRows[0]] .. table.starts[filteredRows[0] + 1] - 1:
      let baseIndex = int(table.bases[entryIndex])
      let lowerRow = int(table.followers[entryIndex])
      if baseIndex div rowValues != baseIndex mod rowValues or lowerRow != baseIndex mod rowValues:
        continue
      let blackCount = popcountValues[baseIndex mod rowValues]
      if blackCount < bestMin:
        bestMin = blackCount
      if blackCount > bestMax:
        bestMax = blackCount
    if bestMax < 0:
      return "Impossible"
    return $(bestMax - bestMin)
  var minimumCost = newSeq[int](rowValues * rowValues)
  var maximumCost = newSeq[int](rowValues * rowValues)
  for stateIndex in 0 .. rowValues * rowValues - 1:
    minimumCost[stateIndex] = unreachable
    maximumCost[stateIndex] = unreachable
  for entryIndex in table.starts[filteredRows[0]] .. table.starts[filteredRows[0] + 1] - 1:
    let baseIndex = int(table.bases[entryIndex])
    if baseIndex div rowValues != baseIndex mod rowValues:
      continue
    let lowerRow = int(table.followers[entryIndex])
    let blackCount = popcountValues[baseIndex div rowValues] + popcountValues[lowerRow]
    let stateIndex = baseIndex div rowValues * rowValues + lowerRow
    if blackCount < minimumCost[stateIndex] or minimumCost[stateIndex] == unreachable:
      minimumCost[stateIndex] = blackCount
    if blackCount > maximumCost[stateIndex]:
      maximumCost[stateIndex] = blackCount
  for rowIndex in 1 .. heightValue - 2:
    var nextMinimum = newSeq[int](rowValues * rowValues)
    var nextMaximum = newSeq[int](rowValues * rowValues)
    for stateIndex in 0 .. rowValues * rowValues - 1:
      nextMinimum[stateIndex] = unreachable
      nextMaximum[stateIndex] = unreachable
    for entryIndex in table.starts[filteredRows[rowIndex]] .. table.starts[filteredRows[rowIndex] + 1] - 1:
      let baseIndex = int(table.bases[entryIndex])
      if minimumCost[baseIndex] == unreachable:
        continue
      let lowerRow = int(table.followers[entryIndex])
      let stateIndex = (baseIndex mod rowValues) * rowValues + lowerRow
      let addedBlack = popcountValues[lowerRow]
      let candidateMin = minimumCost[baseIndex] + addedBlack
      let candidateMax = maximumCost[baseIndex] + addedBlack
      if candidateMin < nextMinimum[stateIndex] or nextMinimum[stateIndex] == unreachable:
        nextMinimum[stateIndex] = candidateMin
      if candidateMax > nextMaximum[stateIndex]:
        nextMaximum[stateIndex] = candidateMax
    minimumCost = nextMinimum
    maximumCost = nextMaximum
  var bestMin = 1 shl 29
  var bestMax = -1
  for entryIndex in table.starts[filteredRows[heightValue - 1]] .. table.starts[filteredRows[heightValue - 1] + 1] - 1:
    let baseIndex = int(table.bases[entryIndex])
    if minimumCost[baseIndex] == unreachable:
      continue
    let lowerRow = int(table.followers[entryIndex])
    if lowerRow != baseIndex mod rowValues:
      continue
    if minimumCost[baseIndex] < bestMin:
      bestMin = minimumCost[baseIndex]
    if maximumCost[baseIndex] > bestMax:
      bestMax = maximumCost[baseIndex]
  if bestMax < 0:
    return "Impossible"
  return $(bestMax - bestMin)
```

The first row repeats upward at the edge.
The last row repeats downward in the final check.
An empty final state set means no original image exists.

**Case loop.** The driver images each case and prints one difference.

```nim
var caseNumber = 1
while true:
  let widthValue = nextInt(inputData, scanPos)
  let heightValue = nextInt(inputData, scanPos)
  if widthValue == 0 and heightValue == 0:
    break
  var filteredRows = newSeq[int](heightValue)
  for rowIndex in 0 .. heightValue - 1:
    filteredRows[rowIndex] = nextImageRow(inputData, scanPos, widthValue)
  appendOutput("Case " & $caseNumber & ": " & solveImage(widthValue, heightValue, filteredRows))
  outputBuffer.add '\n'
  caseNumber += 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

The zero header stops the loop.
Row lines supply exactly `W` characters each.
The final flush writes the answer buffer.

## Complexity

The table is built once per width and reused for all cases.

| phase | time | space |
|---|---|---|
| table build | one pass over `2^(3W)` row triples | grouped triples |
| input read | one pass over image characters | one input string |
| row DP | `H` sweeps of grouped triples | two state arrays |
| output | one buffered line per case | block buffer |

Width eight has `256` row values, so grouping keeps the DP small.

| measure | Big O |
|---|---|
| time per width | O(2^(3W) * W) to build |
| time per case | O(H * 2^(3W) / 2^W) transitions |
| space | O(2^(3W)) table bytes plus two state arrays |

Brute force would test all `2^(W*H)` original images.
The row DP tests only consistent row pairs.
