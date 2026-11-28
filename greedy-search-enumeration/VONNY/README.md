# VONNY — Vonny and her dominos (SPOJ)

<https://www.spoj.com/problems/VONNY/>

## Problem

A standard double-six domino set must cover a 7 by 8 box of labeled squares. Each domino spans two adjacent squares whose labels match its own; count the arrangements.

Input starts with the test count. Each case holds 56 integers, the labels of a 7 by 8 grid in row order. Every label runs from 0 to 6. Output one count per case.

A solvable box holds eight squares of each label, since the full set has eight ends of every value.

The judge bounds are these.

| Quantity | Bound |
| --- | --- |
| Test cases | given on the first input line |
| Box size | 7 rows by 8 columns, 56 squares |
| Labels | 0 to 6 |
| Dominoes | 28 |
| Time limit | 20000 ms |
| Memory limit | 1536 MB |

The fixed grid size keeps each search node small.

The sample input and output follow verbatim.

```
2
0 3 0 2 2 0 2 3 
1 5 6 5 5 1 2 2 
3 4 1 4 5 4 4 4 
6 6 1 0 5 2 3 0 
4 0 3 2 4 1 6 0 
1 4 1 5 6 6 3 0 
1 2 6 5 5 6 3 3 

5 3 1 0 0 1 6 3 
0 2 0 4 1 2 5 2 
1 5 3 5 6 4 6 4 
0 5 0 2 0 4 6 2 
4 5 3 6 0 6 1 1 
2 3 5 3 4 4 5 3 
2 1 1 6 6 2 4 3 

```

```
18
1
```

## Idea

Place one domino at a time, always covering the square with the fewest legal partners. Think of solving a jigsaw by grabbing the piece that fits in the fewest spots first.

The program keeps two bitmaps. One marks covered squares, and the other marks used dominoes. At each step it scans the 56 squares and picks the uncovered square with the smallest number of valid placements. A square with no partner ends that branch. Otherwise the program branches over each free neighbor.

Enumerating all perfect matchings of the grid first would test millions of tilings that fail the label rule. Choosing the hardest square prunes those branches early.

Fewest choices first keeps the search tree small.

## Why It Works

Four facts justify the search.

1. The full set holds each pair `(a, b)` with `a <= b <= 6` once. That gives 28 pieces and 56 ends. Label `l` appears `l` times with a smaller partner, once in the double, and `6 - l` times with a larger partner. The sum is eight per label.
2. Any tiling pairs a chosen uncovered square with one adjacent square. Trying each free neighbor in turn lists every tiling once and never repeats one.
3. The minimum-remaining-values rule keeps all tilings, since it only changes the order of exploration. A square with zero partners proves that branch cannot complete, so the program returns at once.
4. The bitmap tests are integer operations. The recursion depth never exceeds 28, one placement per piece.

The table assigns a unique bit to each piece and square.

| Term | Meaning |
| --- | --- |
| `cellMask[p]` | single-bit mask for square `p` |
| `dominoIndex(low, high)` | id of the bone with ends `low` and `high` |
| `neighborMask[p][k]` | both squares covered by one placement |
| `covered` | bitmap of filled squares |
| `usedDomino` | bitmap of consumed bones |
| `allCellsMask` | all 56 squares set |

The generator checks the two sample boxes at 18 and 1 arrangements. A label count other than eight lets the program skip the search and print zero.

| Label | Count in sample box 1 |
| --- | --- |
| 0 | 8 |
| 1 | 8 |
| 2 | 8 |
| 3 | 8 |
| 4 | 8 |
| 5 | 8 |
| 6 | 8 |

All seven counts match, so the search runs and returns 18.

## Code

**Input setup.** Constants, bulk input, and the digit scanner set up parsing.

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

The scanner skips blank lines between cases and allocates no token. Reading and scanning cost one pass over the input.

**Static tables.** Static tables describe the grid, while label tables depend on the case.

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
  for cellIdx in 0 ..< cellTotal:
    cellMask[cellIdx] = 1 shl cellIdx
    allCellsMask = allCellsMask or cellMask[cellIdx]
  for dominoIdx in 0 ..< dominoTotal:
    dominoMask[dominoIdx] = 1 shl dominoIdx
  for cellIdx in 0 ..< cellTotal:
    let row = cellIdx div rowWidth
    let col = cellIdx mod rowWidth
    var count = 0
    if col + 1 < rowWidth:
      neighborCell[cellIdx][count] = cellIdx + 1
      count += 1
    if row + 1 < rowTotal:
      neighborCell[cellIdx][count] = cellIdx + rowWidth
      count += 1
    if col > 0:
      neighborCell[cellIdx][count] = cellIdx - 1
      count += 1
    if row > 0:
      neighborCell[cellIdx][count] = cellIdx - rowWidth
      count += 1
    neighborCount[cellIdx] = count
    for neighborIdx in 0 ..< count:
      let adjCell = neighborCell[cellIdx][neighborIdx]
      neighborMask[cellIdx][neighborIdx] = cellMask[cellIdx] or cellMask[adjCell]

proc prepareLabels() =
  for cellIdx in 0 ..< cellTotal:
    for neighborIdx in 0 ..< neighborCount[cellIdx]:
      let adjCell = neighborCell[cellIdx][neighborIdx]
      let low = cellLabel[cellIdx]
      let high = cellLabel[adjCell]
      if low <= high:
        neighborDomino[cellIdx][neighborIdx] = dominoIndex(low, high)
      else:
        neighborDomino[cellIdx][neighborIdx] = dominoIndex(high, low)
```

`prepareStatic` visits 56 squares once and stores at most four neighbors each. `prepareLabels` runs once per case over the same fixed pairs. The tables are reused, so no case allocates new storage.

**Backtracking search.** The search counts complete tilings after pruning dead branches.

```nim
var answerCount: int64

proc search(covered: int, usedDomino: int) =
  if covered == allCellsMask:
    answerCount += 1
    return
  var bestCell = -1
  var bestCount = maxNeighbors + 1
  for cellIdx in 0 ..< cellTotal:
    if (covered and cellMask[cellIdx]) != 0:
      continue
    var count = 0
    for neighborIdx in 0 ..< neighborCount[cellIdx]:
      if (covered and cellMask[neighborCell[cellIdx][neighborIdx]]) != 0:
        continue
      if (usedDomino and dominoMask[neighborDomino[cellIdx][neighborIdx]]) == 0:
        count += 1
    if count < bestCount:
      bestCount = count
      bestCell = cellIdx
      if count == 0:
        break
  if bestCount == 0:
    return
  for neighborIdx in 0 ..< neighborCount[bestCell]:
    let adjCell = neighborCell[bestCell][neighborIdx]
    if (covered and cellMask[adjCell]) != 0:
      continue
    let used = dominoMask[neighborDomino[bestCell][neighborIdx]]
    if (usedDomino and used) == 0:
      search(covered or neighborMask[bestCell][neighborIdx], usedDomino or used)
```

The candidate scan costs constant work per node, since the grid is fixed. Returning on a zero count removes a branch before deeper work. The depth stays at most 28.

**Case driver.** The main loop rejects bad label counts and prints the answer.

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
  for cellIdx in 0 ..< cellTotal:
    cellLabel[cellIdx] = nextInt(inputData, scanPos)
  var labelCount: array[labelTotal, int]
  for cellIdx in 0 ..< cellTotal:
    labelCount[cellLabel[cellIdx]] += 1
  var possible = true
  for labelIdx in 0 ..< labelTotal:
    if labelCount[labelIdx] != perLabelCount:
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

The count check scans 56 squares per case. `appendOutput` writes one block after the buffer passes the flush size, then writes the remainder once.

## Complexity

The grid is fixed, so each node has a constant cost.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(56T) | one input string |
| Static tables | O(56 + 28) once | fixed arrays |
| Label check per case | O(56) | 7 counters |
| Search | O(224) per visited node | recursion depth 28 |

The node count depends on the box, but each node stays small.

The totals use the case count and the visited node count.

| Measure | Big O |
| --- | --- |
| Time | O(56T + N) where N counts search nodes |
| Space | O(56 + 28) |

Enumerating all perfect matchings of the grid checks millions of tilings that fail the label rule.
