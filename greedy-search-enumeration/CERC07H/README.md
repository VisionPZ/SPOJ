# CERC07H — Hexagonal Parcels (SPOJ)

<https://www.spoj.com/problems/CERC07H/>

## Problem

Buy the fewest hexagonal parcels so four owned areas become connected. Each parcel costs one unit, and parcels already owned by the investor cost nothing.

A scenario starts with land size `H` from 2 to 20, followed by `2H-1` rows of parcel characters. Row lengths grow from `H` to `2H-1` and fall back to `H`. Spaces may appear anywhere between parcel characters. Dots are unowned land; `A`, `B`, `C`, and `D` mark four connected owned areas. A line containing `0` ends the input. Print `You have to buy P parcels.`

| item | bound |
|---|---|
| land size H | 2 to 20 |
| parcels | up to 1141 |
| owned areas | exactly 4 |
| judge limit | 1000 ms, 1536 MB |

The cost of a parcel is one, so the answer is a minimum Steiner tree on four terminals.

Sample input:

```
4
   B . . C
  . . . . C
 . A . . C .
. A A . . . .
 . A . . . .
  . . . D D
   . . . .

0
```

Sample output:

```
You have to buy 4 parcels.
```

## Idea

Grow four small trees at once, like four crews building roads toward a shared meeting point. A subset of areas has a cheapest way to reach any parcel; merging two subsets at the same parcel avoids paying for that parcel twice. Relaxing edges afterwards spreads each combined result through the hex grid. There are only sixteen subsets, so this replaces a search over all parcel subsets with sixteen shortest-path passes. Without the subset merging, each area would be connected alone and the shared parcels would be counted twice.

## Why It Works

1. A parcel already owned costs zero, and any other parcel costs one.
2. Every area is connected, so reaching any parcel of an area is free once that area is reached.
3. The cheapest subtree for a subset ends at some parcel; every cell can serve as that endpoint.
4. Two subtrees meeting at one parcel share that parcel, so its cost is subtracted once when merged.
5. Hex edges spread a combined subtree to nearby parcels at the cost of the new parcel.
6. After all sixteen subsets are processed, the full set has the minimum Steiner tree.

| term | meaning |
|---|---|
| `cellCosts` | one for unowned parcels, zero for owned ones |
| `cellAreas` | area bits for each parcel |
| `distances` | best cost per subset and endpoint parcel |
| `subsetMask` | four-bit set of areas already connected |
| `neighborLists` | up to six adjacent parcels per cell |

The subtraction rule keeps shared parcels from being charged twice.

The oracle tries bought sets in growing size for the sample:

```
zero bought parcels   areas still separated
one bought parcel     areas still separated
two bought parcels    areas still separated
three bought parcels  areas still separated
four bought parcels   all four areas connected
```

The first successful size is four, matching the sample answer.

## Code

**Input and grid.** The reader skips spaces and builds six-neighbor lists.

```nim
const flushBlockBytes = 1 shl 17
const areaCount = 4
const subsetCount = 16
const infiniteCost = 1000000000

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

proc nextCell(data: string, pos: var int): char =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let cell = data[pos]
  pos += 1
  return cell

proc areaBit(cell: char): int =
  if cell == 'A':
    return 1
  if cell == 'B':
    return 2
  if cell == 'C':
    return 4
  if cell == 'D':
    return 8
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

A cell's column coordinate is `offset + 2 * positionInRow`.
Neighbors in adjacent rows differ by one column coordinate.
Owned cells carry zero cost, so paths through them stay free.

**Steiner subset relaxation.** Merges at each cell are followed by a shortest-path pass.

```nim
while true:
  let landSize = nextInt(inputData, scanPos)
  if landSize == 0:
    break
  let rowCount = 2 * landSize - 1
  var rowLengths = newSeq[int](rowCount)
  var rowOffsets = newSeq[int](rowCount)
  var rowStarts = newSeq[int](rowCount)
  var cellCount = 0
  for rowIndex in 0 .. rowCount - 1:
    rowLengths[rowIndex] = landSize + min(rowIndex, rowCount - 1 - rowIndex)
    if rowIndex < landSize:
      rowOffsets[rowIndex] = landSize - 1 - rowIndex
    else:
      rowOffsets[rowIndex] = rowIndex - landSize + 1
    rowStarts[rowIndex] = cellCount
    cellCount += rowLengths[rowIndex]
  var cellColumns = newSeq[int](cellCount)
  var cellCosts = newSeq[int](cellCount)
  var cellAreas = newSeq[int](cellCount)
  for rowIndex in 0 .. rowCount - 1:
    for positionInRow in 0 .. rowLengths[rowIndex] - 1:
      let cellIndex = rowStarts[rowIndex] + positionInRow
      cellColumns[cellIndex] = rowOffsets[rowIndex] + 2 * positionInRow
      let cell = nextCell(inputData, scanPos)
      cellAreas[cellIndex] = areaBit(cell)
      if cell == '.':
        cellCosts[cellIndex] = 1
      else:
        cellCosts[cellIndex] = 0
  proc findCell(rowIndex: int, columnValue: int): int =
    if rowIndex < 0 or rowIndex >= rowCount:
      return -1
    let difference = columnValue - rowOffsets[rowIndex]
    if difference < 0 or difference mod 2 != 0:
      return -1
    let positionInRow = difference div 2
    if positionInRow >= rowLengths[rowIndex]:
      return -1
    return rowStarts[rowIndex] + positionInRow
  var neighborLists = newSeq[seq[int]](cellCount)
  for rowIndex in 0 .. rowCount - 1:
    for positionInRow in 0 .. rowLengths[rowIndex] - 1:
      let cellIndex = rowStarts[rowIndex] + positionInRow
      let columnValue = cellColumns[cellIndex]
      var neighborList: seq[int] = @[]
      let sameLeft = findCell(rowIndex, columnValue - 2)
      if sameLeft >= 0:
        neighborList.add sameLeft
      let sameRight = findCell(rowIndex, columnValue + 2)
      if sameRight >= 0:
        neighborList.add sameRight
      let aboveLeft = findCell(rowIndex - 1, columnValue - 1)
      if aboveLeft >= 0:
        neighborList.add aboveLeft
      let aboveRight = findCell(rowIndex - 1, columnValue + 1)
      if aboveRight >= 0:
        neighborList.add aboveRight
      let belowLeft = findCell(rowIndex + 1, columnValue - 1)
      if belowLeft >= 0:
        neighborList.add belowLeft
      let belowRight = findCell(rowIndex + 1, columnValue + 1)
      if belowRight >= 0:
        neighborList.add belowRight
      neighborLists[cellIndex] = neighborList
  var distances = newSeq[int](subsetCount * cellCount)
  for stateIndex in 0 .. subsetCount * cellCount - 1:
    distances[stateIndex] = infiniteCost
  for areaIndex in 0 .. areaCount - 1:
    let areaMask = 1 shl areaIndex
    for cellIndex in 0 .. cellCount - 1:
      if (cellAreas[cellIndex] and areaMask) != 0:
        distances[areaMask * cellCount + cellIndex] = 0
  for subsetMask in 1 .. subsetCount - 1:
    var firstPart = (subsetMask - 1) and subsetMask
    while firstPart > 0:
      let secondPart = subsetMask xor firstPart
      for cellIndex in 0 .. cellCount - 1:
        let firstCost = distances[firstPart * cellCount + cellIndex]
        let secondCost = distances[secondPart * cellCount + cellIndex]
        if firstCost >= infiniteCost or secondCost >= infiniteCost:
          continue
        let combinedCost = firstCost + secondCost - cellCosts[cellIndex]
        let targetIndex = subsetMask * cellCount + cellIndex
        if combinedCost < distances[targetIndex]:
          distances[targetIndex] = combinedCost
      firstPart = (firstPart - 1) and subsetMask
    var visited = newSeq[bool](cellCount)
    while true:
      var bestCell = -1
      var bestCost = infiniteCost
      for cellIndex in 0 .. cellCount - 1:
        let candidate = distances[subsetMask * cellCount + cellIndex]
        if not visited[cellIndex] and candidate < bestCost:
          bestCost = candidate
          bestCell = cellIndex
      if bestCell == -1:
        break
      visited[bestCell] = true
      for neighborIndex in neighborLists[bestCell]:
        if visited[neighborIndex]:
          continue
        let nextCost = bestCost + cellCosts[neighborIndex]
        let targetIndex = subsetMask * cellCount + neighborIndex
        if nextCost < distances[targetIndex]:
          distances[targetIndex] = nextCost
  var minimumParcels = infiniteCost
  for cellIndex in 0 .. cellCount - 1:
    let candidate = distances[(subsetCount - 1) * cellCount + cellIndex]
    if candidate < minimumParcels:
      minimumParcels = candidate
  appendOutput("You have to buy " & $minimumParcels & " parcels.")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each subset is merged before its shortest-path pass.
The merge subtracts the endpoint cost once.
The minimum over all endpoints is the answer.

## Complexity

Sixteen subset passes dominate the work for one land.

| phase | time | space |
|---|---|---|
| input read | one pass over parcel characters | one input string |
| neighbor build | six lookups per parcel | six lists per parcel |
| subset passes | sixteen times parcel squared | sixteen costs per parcel |
| output | one write per block | block buffer |

The subset passes cost more than parsing but stay small for 1141 parcels.

| measure | Big O |
|---|---|
| time per scenario | O(16 * parcels^2) |
| space | O(16 * parcels) |

Trying every bought-parcel subset would grow as two to the number of parcels. The subset DP keeps the four terminals explicit and avoids that exponential search.
