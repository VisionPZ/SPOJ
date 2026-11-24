## Problem

Each case lists sellers, buyers, and offers of the form seller, buyer, goods. A seller ships to one buyer, and a buyer receives from one seller. Choose the pairs that maximize the total goods shipped, and print one total per case.

| Quantity | Bound |
| --- | --- |
| Test cases | t <= 1000 |
| Selling cities | C1 <= 100 |
| Buying cities | C2 <= 100 |
| Goods per offer | g <= 100 |
| Time limit | 1371 ms |
| Memory limit | 1536 MB |
| Source limit | 50000 B |

The 100-city bound makes a cubic matching pass practical.

## Idea

The program solves a maximum-weight bipartite matching as a minimum-cost assignment. It stores `-g` for a real offer and zero for a missing offer. Dummy columns let an unused city cost nothing. Each augmentation fixes one more row and may reassign earlier rows.

The matrix uses the smaller city class as rows, so skewed cases shrink the inner scan. One POSIX call fills the input buffer, and a hand scanner reads each integer.

Cost per case: cubic in the smaller city count, with one matrix cell per possible offer.

## Why It Works

Storing `-g` turns the largest goods total into the smallest cost. An optimal matching leaves no positive offer between two unused cities, so zero-cost padding changes no answer. Transposing a wide case keeps rows no longer than columns.

Each term in the update has one job.

`costCells` stores `-g` at the offset `rowIndex * colCount + colIndex` for one offer.

`delta` is the smallest reduced cost on the current frontier.

`rowPotential[assignedRow[k]] += delta` and `colPotential[k] -= delta` keep reduced costs nonnegative.

The trailing `'!'` stops the scanner after the last token. It sorts after spaces and before digits, so no token is lost.

A script prints the first sample case as a cost matrix. The last row and column are padding.

```
sellers 3 buyers 2 padded size 3
row 1:  -10    0    0
row 2:  -19  -11    0
row 3:    0   -1    0
best total goods 21
```

Rows 1 and 2 take costs -10 and -11, so the matching ships 21 goods.

## Code

The reader fills one buffer with bulk reads and parses it in place.

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

The buffer doubles only when a chunk would overflow it. The trailing marker ends the scan without a length test per digit. All values are nonnegative, so the scanner needs no sign branch.

One output buffer collects every answer and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush threshold bounds memory at one block. The program writes at most one thousand short lines, so one final flush is usual.

The matching pass uses fixed arrays and potentials.

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

The outer loop runs once per row, and each scan visits at most that many columns. The `generation` mark avoids clearing the visited array between rows. The `previousCol` chain reassigns earlier rows after one free column appears.

The driver builds one matrix per case and reads offers until the terminating trio.

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

The matrix starts at zero, which is the cost of an unused city. Repeated offers keep the largest goods value in each cell. The bounds check skips a city number outside its class.

## Complexity

Bulk reading costs O(input bytes), and the scanner touches each token once. Matrix construction costs O(offers) per case. The matching pass costs O(R^2 * C) with R rows in the smaller class and C columns in the larger class. Fixed arrays use O(C^2) space.

Total time is O(input bytes + t * R^2 * C), and total space is O(input bytes + C^2). A naive search over all matchings costs factorial time, which is impossible at 100 cities.
