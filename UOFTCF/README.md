<https://www.spoj.com/problems/UOFTCF/>

## Problem

Alice and Bob walk down a grid from row 1 to row R. Each second they move one row lower and may shift one column left or right. They cannot step on blocked cells or share a cell. Count the most seconds they can spend side by side, or report Detour when no pair of paths reaches the last row.

Input starts with S sidewalks. Each sidewalk gives R and C, then R strings of C cells. A dot is walkable and a hash is blocked. Output prints one maximum or Detour per sidewalk.

| item | bound |
|---|---|
| sidewalks S | 1 to 50 |
| rows R | 1 to 50 |
| columns C | 1 to 50 |
| judge limit | 3000 ms, 1536 MB |

The two walkers move independently but share the same grid. A score is earned on a row where their columns differ by one.

Sample input:

```
2
5 5
#....
..##.
.#...
#.#..
....#
2 4
.##.
..##
```

Sample output:

```
4
Detour
```

## Idea

Track both walkers at once with one state per pair of columns, like two fingers following separate lanes down a staircase. Each state holds the best hand-holding time when Alice and Bob end that row in those columns. Move to the next row by trying the three steps for each walker. A negative score marks a state that cannot be reached.

## Why It Works

1. A state is the ordered pair of columns for Alice and Bob on one row.
2. On row 1, a pair scores one when its columns differ by one.
3. From a state, each walker chooses a step of -1, 0, or +1.
4. The next pair is valid when both cells are dots and the columns differ.
5. The next score adds one exactly when the new columns differ by one.
6. After the last row, the largest reachable score is the answer.
7. No reachable state means Detour.

| term | meaning |
|---|---|
| `gridRows` | walkable cell string for each row |
| `stateSize` | number of ordered column pairs, C squared |
| `previousScores` | best score for each pair on the current row |
| `currentScores` | scores for the next row |
| `startScore` | row 1 score for an initial pair |
| `addedScore` | one for a side-by-side pair, else zero |
| `bestScore` | maximum score over all final pairs |

In the sample, Alice uses columns 3, 2, 3, 4, 3 and Bob uses columns 4, 5, 4, 5, 4. Their gaps are 1, 3, 1, 1, 1, so they hold hands on rows 1, 3, 4, and 5. The total is 4. In the second sidewalk, Bob starts at column 4 and no reachable cell exists on row 2, so every state is unreachable and the answer is Detour.

## Code

**Input and scanner.** The reader loads all lines and extracts numbers and grid rows.

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

proc nextGridRow(data: string, pos: var int, columnCount: int): string =
  while pos < data.len and data[pos] != '.' and data[pos] != '#':
    pos += 1
  var collected = 0
  while collected < columnCount and pos < data.len:
    if data[pos] == '.' or data[pos] == '#':
      result.add data[pos]
      collected += 1
    pos += 1
```

The row reader skips line breaks and other separators.
It stops after exactly C cell characters.
Blocked cells stay in the string for direct indexing.

**Row transitions.** Every pair of steps creates one candidate for the next row.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let sidewalkCount = nextInt(inputData, scanPos)
for sidewalkIndex in 0 .. sidewalkCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var gridRows = newSeq[string](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    gridRows[rowIndex] = nextGridRow(inputData, scanPos, columnCount)
  let stateSize = columnCount * columnCount
  var previousScores = newSeq[int](stateSize)
  var currentScores = newSeq[int](stateSize)
  for stateIndex in 0 .. stateSize - 1:
    previousScores[stateIndex] = -1
  for aliceColumn in 0 .. columnCount - 1:
    if gridRows[0][aliceColumn] != '.':
      continue
    for bobColumn in 0 .. columnCount - 1:
      if aliceColumn == bobColumn or gridRows[0][bobColumn] != '.':
        continue
      let gap = aliceColumn - bobColumn
      let startScore = if gap == 1 or gap == -1: 1 else: 0
      previousScores[aliceColumn * columnCount + bobColumn] = startScore
  for rowIndex in 1 .. rowCount - 1:
    for stateIndex in 0 .. stateSize - 1:
      currentScores[stateIndex] = -1
    for aliceColumn in 0 .. columnCount - 1:
      for bobColumn in 0 .. columnCount - 1:
        let scoreHere = previousScores[aliceColumn * columnCount + bobColumn]
        if scoreHere < 0:
          continue
        for aliceStep in -1 .. 1:
          let nextAlice = aliceColumn + aliceStep
          if nextAlice < 0 or nextAlice >= columnCount:
            continue
          if gridRows[rowIndex][nextAlice] != '.':
            continue
          for bobStep in -1 .. 1:
            let nextBob = bobColumn + bobStep
            if nextBob < 0 or nextBob >= columnCount:
              continue
            if gridRows[rowIndex][nextBob] != '.' or nextAlice == nextBob:
              continue
            let gap = nextAlice - nextBob
            let addedScore = if gap == 1 or gap == -1: 1 else: 0
            let targetIndex = nextAlice * columnCount + nextBob
            let candidateScore = scoreHere + addedScore
            if candidateScore > currentScores[targetIndex]:
              currentScores[targetIndex] = candidateScore
    swap(previousScores, currentScores)
  var bestScore = -1
  for stateIndex in 0 .. stateSize - 1:
    if previousScores[stateIndex] > bestScore:
      bestScore = previousScores[stateIndex]
  if bestScore < 0:
    appendOutput("Detour\n")
  else:
    appendOutput($bestScore)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Unreachable pairs start at minus one.
Both walkers clip their steps to the grid.
The row arrays swap after each transition.

## Complexity

Each row updates at most C squared states with nine step pairs.

| phase | time | space |
|---|---|---|
| read sidewalk | one row reader per line | one string per row |
| initial pairs | C squared checks | two C squared arrays |
| row transitions | nine updates per pair | none extra |
| final answer | one scan of all pairs | none extra |

| measure | Big O |
|---|---|
| time per sidewalk | O(R C^2) |
| space per sidewalk | O(R C + C^2) |

Enumerating all pairs of complete walks grows exponentially in R. The row-by-row table keeps only the best score for each column pair.
