## Problem

Count the arrangements of a standard double-six domino set that cover a labeled 7 by 8 box. Each square carries a label from 0 to 6. A domino covers two adjacent squares when its two numbers match those square labels in either order. Every one of the 28 dominoes is used once. Print one count per test case.

| Quantity | Bound |
| --- | --- |
| Test cases | given on the first input line |
| Box size | 7 rows by 8 columns, 56 squares |
| Labels | 0 to 6 |
| Time limit | 20000 ms |
| Memory limit | 1536 MB |

A solvable box holds eight squares of each label, because the full set has eight ends of every label.

## Idea

The program solves an exact cover problem with backtracking and two integer bitmaps. One bitmap marks covered squares, and the other marks used dominoes. Before each branch, the program picks the uncovered square with the fewest legal partners. A square with no partner ends that branch at once.

Each search node scans at most 56 squares and four neighbors each, so one node costs constant work. Enumerating every perfect matching of the grid first would test millions of tilings that fail the label rule.

## Why It Works

The full set holds each pair `(a, b)` with `a <= b <= 6` exactly once. That gives 28 pieces and 56 ends. Label `l` appears in `l` pieces with a smaller partner. It appears once in the double piece and in `6 - l` pieces with a larger partner. The sum is eight, so a solvable box has eight squares per label.

Any tiling pairs a chosen uncovered square with exactly one adjacent square. Trying each free neighbor in turn therefore lists every tiling once and never repeats one. Choosing the square with the fewest legal partners keeps all tilings and cuts dead branches early.

These marking rules give each piece and square a unique bit.

- `low * labelTotal + high - (low * (low + 1)) div 2` gives one id from a sorted pair.
- `1 shl p` sets the bit for square `p`.
- `covered or neighborMask[bestCell][k]` marks the two squares filled by a placement.
- `usedDomino or used` records the consumed piece.

The script in `gen.py` checks the first sample box at 18 arrangements and the second at 1.

## Code

The input is read once, and the hand scanner walks the single buffer. The output buffer flushes in large blocks.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const cellTotal = 56
const rowWidth = 8
const rowTotal = 7
const dominoTotal = 28
const labelTotal = 7
const perLabelCount = 8
const maxNeighbors = 4

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The scanner skips blank lines between cases. It never allocates a token object. Reading and scanning cost one pass over the input.

The tables are built once. The neighbor list depends only on the grid shape, while each piece id depends on that case's labels.

```nim
var cellMask: array[cellTotal, int]
var allCellsMask = 0
var dominoMask: array[dominoTotal, int]
var neighborCount: array[cellTotal, int]
var neighborCell: array[cellTotal, array[maxNeighbors, int]]
var neighborDomino: array[cellTotal, array[maxNeighbors, int]]
var neighborMask: array[cellTotal, array[maxNeighbors, int]]
var cellLabel: array[cellTotal, int]

proc dominoIndex(low: int, high: int): int =
  return low * labelTotal + high - (low * (low + 1)) div 2

proc prepareStatic() =
  for p in 0 ..< cellTotal:
    cellMask[p] = 1 shl p
    allCellsMask = allCellsMask or cellMask[p]
  for d in 0 ..< dominoTotal:
    dominoMask[d] = 1 shl d
  for p in 0 ..< cellTotal:
    let row = p div rowWidth
    let col = p mod rowWidth
    var count = 0
    if col + 1 < rowWidth:
      neighborCell[p][count] = p + 1
      count += 1
    if row + 1 < rowTotal:
      neighborCell[p][count] = p + rowWidth
      count += 1
    if col > 0:
      neighborCell[p][count] = p - 1
      count += 1
    if row > 0:
      neighborCell[p][count] = p - rowWidth
      count += 1
    neighborCount[p] = count
    for k in 0 ..< count:
      let q = neighborCell[p][k]
      neighborMask[p][k] = cellMask[p] or cellMask[q]

proc prepareLabels() =
  for p in 0 ..< cellTotal:
    for k in 0 ..< neighborCount[p]:
      let q = neighborCell[p][k]
      let low = cellLabel[p]
      let high = cellLabel[q]
      if low <= high:
        neighborDomino[p][k] = dominoIndex(low, high)
      else:
        neighborDomino[p][k] = dominoIndex(high, low)
```

`prepareStatic` visits 56 squares once and stores at most four neighbors each. `prepareLabels` runs once per case over the same fixed neighbor pairs. The tables are reused, so no case allocates new storage.

The search counts complete tilings. It stops at the first square with no legal partner and branches only over valid placements.

```nim
var answerCount: int64

proc search(covered: int, usedDomino: int) =
  if covered == allCellsMask:
    answerCount += 1
    return
  var bestCell = -1
  var bestCount = maxNeighbors + 1
  for p in 0 ..< cellTotal:
    if (covered and cellMask[p]) != 0:
      continue
    var count = 0
    for k in 0 ..< neighborCount[p]:
      if (covered and cellMask[neighborCell[p][k]]) != 0:
        continue
      if (usedDomino and dominoMask[neighborDomino[p][k]]) == 0:
        count += 1
    if count < bestCount:
      bestCount = count
      bestCell = p
      if count == 0:
        break
  if bestCount == 0:
    return
  for k in 0 ..< neighborCount[bestCell]:
    let q = neighborCell[bestCell][k]
    if (covered and cellMask[q]) != 0:
      continue
    let used = dominoMask[neighborDomino[bestCell][k]]
    if (usedDomino and used) == 0:
      search(covered or neighborMask[bestCell][k], usedDomino or used)
```

The depth never exceeds 28 placements, one per piece. The bitmap tests keep each move to a few integer operations. Returning on a zero count removes a branch before any deeper work.

The main loop rejects a box whose label counts differ from eight. Otherwise it resets the counter and runs the search.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

prepareStatic()
let caseCount = nextInt(inputData, scanPos)
for caseIdx in 0 ..< caseCount:
  for p in 0 ..< cellTotal:
    cellLabel[p] = nextInt(inputData, scanPos)
  var labelCount: array[labelTotal, int]
  for p in 0 ..< cellTotal:
    labelCount[cellLabel[p]] += 1
  var possible = true
  for l in 0 ..< labelTotal:
    if labelCount[l] != perLabelCount:
      possible = false
  if not possible:
    appendOutput("0")
  else:
    prepareLabels()
    answerCount = 0
    search(0, 0)
    appendOutput($(answerCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The count check scans 56 squares per case. `appendOutput` writes one block only after the buffer grows past the flush size, then writes the remainder once at the end.

## Complexity

Input scanning costs O(56T), and the static tables cost O(56 + 28). Each case spends O(56) on the count check and O(97) on piece ids, then enters the search. A search node scans at most 56 squares with four neighbors each, and the recursion is at most 28 levels deep. The total time is O(56T + N × 224), where N is the number of visited nodes. Memory stays at O(56 + 28) for the tables and one output block. A naive pass that enumerates all perfect matchings of the 7 by 8 grid checks millions of tilings that fail the label rule.
