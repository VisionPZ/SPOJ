# SCITIES — Selfish Cities (SPOJ)
<https://www.spoj.com/problems/SCITIES/>

## Problem

Some cities sell goods and others buy goods, and each city trades with only one partner. Given possible seller-buyer trades and the goods each moves, choose trades that maximize the total goods exchanged.

Input: an integer t, then t cases. Each case starts with seller count C1 and buyer count C2. Then come triples seller, buyer, goods, ending with 0 0 0. Output: one integer per case, the maximum goods shipped.

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Test cases | at most 1000 |
| Selling cities C1 | at most 100 |
| Buying cities C2 | at most 100 |
| Goods per offer | at most 100 |
| Judge time limit | 1371 ms |
| Judge memory limit | 1536 MB |

The 100-city bound makes a cubic matching pass practical.

The sample input:

```
3
3 2
1 1 10
2 1 19
2 2 11
3 2 1
0 0 0
4 4
1 1 6
1 2 6
2 1 8
2 3 9
2 4 8
3 2 8
4 3 7
0 0 0
3 2
1 1 10
2 1 21
2 2 11
3 2 1
0 0 0
```

The sample output:

```
21
29
22
```

## Idea

Pair sellers with buyers, then improve one pairing at a time until no swap raises the total goods. The program solves a maximum-weight bipartite matching through minimum-cost assignment. It stores minus the goods for each real offer and zero for a missing offer. The smaller city class supplies the rows, so skewed cases scan fewer cells.

Each augmentation fixes one more row and may reassign earlier rows. One augmentation costs O(row times column) work, and a case runs one augmentation per row. A search over every matching would be factorial, which is impossible at 100 cities.

One row at a time builds the best matching.

## Why It Works

Four facts carry the program.

1. Storing minus the goods turns the largest total into the smallest cost. Negating the final cost restores the goods total.
2. A zero cell for a missing offer acts as a dummy. An unused city therefore costs nothing and never blocks a matching.
3. Transposing a wide case keeps rows no longer than columns. The inner scan then follows the smaller class.
4. Potentials keep reduced costs nonnegative. The smallest reduced cost `delta` updates them, so each frontier step stays valid.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `costCells` | minus goods at `rowIndex * colCount + colIndex` |
| `delta` | smallest reduced cost on the current frontier |
| `previousCol` | parent chain used to reassign earlier rows |
| `generation` | stamp that avoids clearing the visited array |

The trailing exclamation mark stops the scanner after the last token.

A script prints the first sample case as a cost matrix, with padding cells.

```text
sellers 3 buyers 2 padded size 3
row 1: -10   0   0
row 2: -19 -11   0
row 3:   0  -1   0
best cost -21, goods 21
```

Rows 1 and 2 take costs minus 10 and minus 11, so the answer is 21. No rounding applies because every cost is an integer.

## Code

**Bulk reader.** One POSIX call fills a growable buffer in chunks.

```nim
{.push checks: off.}
{.passC: "-O2".}
import posix

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinity = high(int) div 4
const maxCities = 100
const maxCells = maxCities * maxCities
const inputChunkBytes = 1 shl 20

var inputData = newString(inputChunkBytes)
var inputLength = 0
while true:
  if inputLength + inputChunkBytes > inputData.len:
    inputData.setLen(inputData.len * 2)
  let bytesRead = read(0, cast[pointer](addr inputData[inputLength]), inputChunkBytes)
  if bytesRead <= 0:
    break
  inputLength += bytesRead
inputData.setLen(inputLength)
inputData.add '!'

var i = 0

proc nextInt(data: string, pos: var int): int {.inline.} =
  while data[pos] <= ' ':
    pos += 1
  var value = 0
  if data[pos] >= '0':
    value = int(data[pos]) - firstDigitValue
    pos += 1
    if data[pos] >= '0':
      value = value * 10 + int(data[pos]) - firstDigitValue
      pos += 1
      if data[pos] >= '0':
        value = value * 10 + int(data[pos]) - firstDigitValue
        pos += 1
        if data[pos] >= '0':
          value = value * 10 + int(data[pos]) - firstDigitValue
          pos += 1
          if data[pos] >= '0':
            value = value * 10 + int(data[pos]) - firstDigitValue
            pos += 1
            while data[pos] >= '0':
              value = value * 10 + int(data[pos]) - firstDigitValue
              pos += 1
  value
```

The buffer doubles only when a chunk would overflow it. The sentinel ends the scan without a length test per digit. All values are nonnegative, so no sign branch is needed.

**Output helper.** One buffer flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The threshold bounds memory at one block. The program writes at most one thousand short lines.

**Matching pass.** Potentials guide one augmentation per row.

```nim
var costCells: array[0 .. maxCells - 1, int]

proc maxExchange(rowCount: int, colCount: int): int =
  var rowPotential: array[0 .. maxCities, int]
  var colPotential: array[0 .. maxCities, int]
  var assignedRow: array[0 .. maxCities, int]
  var previousCol: array[0 .. maxCities, int]
  var minReducedCost: array[0 .. maxCities, int]
  var visitedMark: array[0 .. maxCities, int]
  var generation = 0
  for r in 1..rowCount:
    assignedRow[0] = r
    generation += 1
    for k in 0..colCount:
      minReducedCost[k] = infinity
    var currentCol = 0
    while true:
      visitedMark[currentCol] = generation
      let currentRow = assignedRow[currentCol]
      let rowBase = (currentRow - 1) * colCount
      var delta = infinity
      var nextCol = 0
      for k in 1..colCount:
        if visitedMark[k] != generation:
          let reducedCost = costCells[rowBase + k - 1] -
                            rowPotential[currentRow] - colPotential[k]
          if reducedCost < minReducedCost[k]:
            minReducedCost[k] = reducedCost
            previousCol[k] = currentCol
          if minReducedCost[k] < delta:
            delta = minReducedCost[k]
            nextCol = k
      for k in 0..colCount:
        if visitedMark[k] == generation:
          rowPotential[assignedRow[k]] += delta
          colPotential[k] -= delta
        else:
          minReducedCost[k] -= delta
      currentCol = nextCol
      if assignedRow[currentCol] == 0:
        break
    while true:
      let backCol = previousCol[currentCol]
      assignedRow[currentCol] = assignedRow[backCol]
      currentCol = backCol
      if currentCol == 0:
        break
  var totalCost = 0
  for k in 1..colCount:
    if assignedRow[k] != 0:
      totalCost += costCells[(assignedRow[k] - 1) * colCount + k - 1]
  -totalCost
```

The outer loop runs once per row. `generation` avoids clearing the visited array. The `previousCol` chain reassigns earlier rows after a free column appears. The pass costs O(row squared times column).

**Driver.** One matrix serves one case.

```nim
let caseCount = nextInt(inputData, i)
for caseIndex in 0..<caseCount:
  let sellerCount = nextInt(inputData, i)
  let buyerCount = nextInt(inputData, i)
  let transposed = sellerCount > buyerCount
  let rowCount = if transposed: buyerCount else: sellerCount
  let colCount = if transposed: sellerCount else: buyerCount
  let cellCount = rowCount * colCount
  for k in 0..<cellCount:
    costCells[k] = 0
  while true:
    let fromCity = nextInt(inputData, i)
    let toCity = nextInt(inputData, i)
    let goods = nextInt(inputData, i)
    if fromCity == 0 and toCity == 0 and goods == 0:
      break
    if fromCity >= 1 and fromCity <= sellerCount and toCity >= 1 and toCity <= buyerCount:
      let rowIndex = if transposed: toCity - 1 else: fromCity - 1
      let colIndex = if transposed: fromCity - 1 else: toCity - 1
      let cellIndex = rowIndex * colCount + colIndex
      if -goods < costCells[cellIndex]:
        costCells[cellIndex] = -goods
  let answer = maxExchange(rowCount, colCount)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

{.pop.}
```

The matrix starts at zero, the cost of an unused city. Repeated offers keep the largest goods value in each cell. The bounds check skips city numbers outside their class.

## Complexity

Reading and matching are the two dominant stages.

| Phase | Time | Space |
| --- | --- | --- |
| Bulk read | O(B) for B input bytes | B bytes |
| Matrix setup | O(offers) per case | 10000 cells |
| Matching pass | O(R squared times C) per case | fixed arrays |
| Output | O(t) lines | one block |
| Total | O(B + t times R squared times C) | O(B + C squared) |

R is the smaller city class and C is the larger one. Both are at most 100.

| Measure | Big O |
| --- | --- |
| Time | O(t times R squared times C) |
| Space | O(B + C squared) |

A search over all matchings is factorial and cannot finish at 100 cities.
