# UOFTCE — A Brief Expedition (SPOJ)

<https://www.spoj.com/problems/UOFTCE/>

## Problem

Visit every store in a mall and return to the car, spending 60 minutes shopping at each store. The stopwatch starts at the first store, so the first walk from the car is free, and the final walk back is timed.

Line 1 holds the mall count `M`. Each mall gives `R C`, then `R` rows of `C` characters. Walls are `#`, open space `.`, stores `S`, and the car `C`. Print one minimum minute count per mall.

| item | bound |
|---|---|
| malls M | 1 to 100 |
| rows R | 1 to 100 |
| columns C | 1 to 100 |
| stores per mall | at least 1, each reachable from the car |
| cars per mall | exactly 1 |
| judge limit | 3000 ms, 1536 MB |

Moving one cell up, down, left, or right takes one minute and cannot cross a wall.

Sample input:

```
2
4 4
..S#
.##C
....
S.#S
1 5
SSCSS
```

Sample output:

```
202
250
```

Those two lines are the exact expected output.

## Idea

Think of the stores as parcels carried back to a depot: after each shop they return to the car, so every store except the first costs a round trip. Send the farthest store first, because its outbound walk happens before the stopwatch starts.

The algorithm runs one breadth-first search from the car, sums the distances to all stores, and subtracts the largest distance. Each mall costs O(RC) for the search. Trying every visit order would need factorial time.

One pass from the car gives every distance the answer needs.

## Why It Works

1. The car is the depot: after each shop the pair returns there to drop items.
2. Let di be the walking distance from the car to store i.
3. The first store's outbound walk is untimed; its return walk is timed.
4. Every later store costs one outbound and one return walk, both timed.
5. Shopping costs 60 minutes per store, so the fixed shopping total is 60K.
6. The walking total is 2 times the sum of di minus the largest di.
7. Putting the farthest store first removes one copy of that largest distance.

| term | meaning |
|---|---|
| `storeIndices` | cell index of every store |
| `carIndex` | cell index of the car |
| `distances` | breadth-first distances from the car |
| `distanceTotal` | sum of distances from car to all stores |
| `farthestStore` | largest of those distances |
| `answer` | shopping time plus timed walking |

The labels above match the identifiers in the code.

The second sample mall is `SSCSS`, with the car in the middle.

| store column | distance from car |
|---|---|
| 1 | 2 |
| 2 | 1 |
| 4 | 1 |
| 5 | 2 |

The sum is 6 and the largest is 2, so the answer is 240 + 12 - 2 = 250.

## Code

**Input and scanner.** The reader stores lines, and a helper pulls each grid row as a string.

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

proc nextGridLine(data: string, pos: var int, width: int): string =
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    pos += 1
  result = ""
  while result.len < width and pos < data.len:
    let cellChar = data[pos]
    if cellChar != '\n' and cellChar != '\r' and cellChar != ' ':
      result.add cellChar
    pos += 1
  return result
```

One newline ends each stored line.
The grid helper skips line breaks before reading cells.
The scanner advances one index per number.

**Breadth-first search.** A single search from the car labels every reachable cell with its distance.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let mallCount = nextInt(inputData, scanPos)
for mallIndex in 0 .. mallCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var grid = newSeq[string](rowCount)
  var carIndex = -1
  var storeIndices = newSeq[int](0)
  for rowIndex in 0 .. rowCount - 1:
    grid[rowIndex] = nextGridLine(inputData, scanPos, columnCount)
    for columnIndex in 0 .. columnCount - 1:
      let cellChar = grid[rowIndex][columnIndex]
      if cellChar == 'C':
        carIndex = rowIndex * columnCount + columnIndex
      elif cellChar == 'S':
        storeIndices.add(rowIndex * columnCount + columnIndex)
  let cellTotal = rowCount * columnCount
  var distances = newSeq[int](cellTotal)
  for cellIndex in 0 .. cellTotal - 1:
    distances[cellIndex] = -1
  var queue = newSeq[int](cellTotal)
  var headIndex = 0
  var tailIndex = 0
  distances[carIndex] = 0
  queue[tailIndex] = carIndex
  tailIndex += 1
  while headIndex < tailIndex:
    let currentIndex = queue[headIndex]
    headIndex += 1
    let currentRow = currentIndex div columnCount
    let currentColumn = currentIndex mod columnCount
    let currentDistance = distances[currentIndex]
    for direction in 0 .. 3:
      var nextRow = currentRow
      var nextColumn = currentColumn
      if direction == 0:
        nextRow -= 1
      elif direction == 1:
        nextRow += 1
      elif direction == 2:
        nextColumn -= 1
      else:
        nextColumn += 1
      if nextRow >= 0 and nextRow < rowCount and nextColumn >= 0 and nextColumn < columnCount:
        let nextIndex = nextRow * columnCount + nextColumn
        if distances[nextIndex] < 0 and grid[nextRow][nextColumn] != '#':
          distances[nextIndex] = currentDistance + 1
          queue[tailIndex] = nextIndex
          tailIndex += 1
```

The car and stores are found while reading rows.
Walls are blocked by the distance check.
The queue holds each cell once.

**Answer.** The distance sum and its largest term give the timed total.

```nim
  var distanceTotal: int64 = 0
  var farthestStore = 0
  for storeIndex in storeIndices:
    let storeDistance = distances[storeIndex]
    distanceTotal = distanceTotal + int64(storeDistance)
    if storeDistance > farthestStore:
      farthestStore = storeDistance
  let answer = int64(60 * storeIndices.len) + int64(2) * distanceTotal - int64(farthestStore)
  appendOutput($answer)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The largest distance is dropped once.
All distances are reachable by the problem guarantee.
The final line flushes the buffered answers.

## Complexity

Each mall reads its grid, searches from the car, and sums store distances.

| phase | time | space |
|---|---|---|
| input scan | one pass over R times C cells | one input string |
| breadth-first search | one visit per open cell | distance and queue arrays |
| answer | one pass over the stores | a few scalar values |

The table shows a separate cost for each phase.

| measure | Big O |
|---|---|
| time per mall | O(RC) |
| space per mall | O(RC) |

Testing every store order would take factorial time instead of one search.

Subtracting the farthest distance captures the free first walk.
