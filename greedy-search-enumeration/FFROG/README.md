# FFROG — Flying Frogs (SPOJ)

<https://www.spoj.com/problems/FFROG/>

## Problem

Frogs sit on cells of a grid. On a turn a prince issues one to K orders; each order moves one frog up or left by any positive distance. The prince with no legal move loses. Decide whether the first prince wins.

The first line holds the test count. Each test starts with m, n and K, followed by m lines with n frog counts. Counts can have up to 101 digits. Print one winner line per test.

| item | bound |
|---|---|
| tests | up to 20 |
| grid | m, n up to 1000, with m times n at most 100000 |
| move limit K | 1 to 1000000000 |
| frogs per cell | 0 to 10 to the power 100 |
| input size | at most 5 MB |
| judge limit | 1000 ms, 1536 MB |

The move limit and the huge counts drive the design.

Sample input:

```
3
1 1 1
837465
2 2 1
0 0
0 1
2 2 2
0 0
0 2
```

Sample output:

```
SmartFrog Wins!.
SmartFrog Wins!.
SensibleFrog Wins!.
```

The last test has two frogs one cell from the corner, and two moves let the first prince finish.

## Idea

A frog sitting at row i and column j behaves like two piles of sizes i and j, like coins in two stacks that only shrink. Up to K orders per turn make this Moore's Nim, whose losing positions have equal digit sums in every binary place modulo K plus one. Count frogs per row and per column, reduce those counts modulo K plus one, then test each binary place. Each cell costs one token read, and each binary place costs O(m + n). Simulating all orders explodes with the move limit, while the digit test stays tiny. Reduce counts first, scan binary places, and name the winner.

## Why It Works

1. Moving a frog up lowers its row pile; moving it left lowers its column pile.
2. A turn changes at most K piles, and repeating an order on one pile equals one larger reduction.
3. Moore's Nim says a position loses when every binary digit total is divisible by K plus one.
4. Frogs sharing a row or column add to the same pile size, so their counts only matter modulo K plus one.
5. A nonzero digit total gives the first prince a winning move.

| term | meaning |
|---|---|
| `modulusValue` | K plus one, the modulus for pile counts |
| `rowHeaps` | frog counts reduced by row |
| `columnHeaps` | frog counts reduced by column |
| `digitWeight` | current power of two in the digit scan |

The scan stops once the weight passes every possible coordinate.

A trace of the last sample test with K equal to 2:

| pile | value | binary digit 0 |
|---|---|---|
| row 1 | 2 frogs | 0 |
| column 1 | 2 frogs | 2 |
| total | 2 modulo 3 | nonzero |

The nonzero total makes the first prince the winner, matching the sample.

## Code

**Input helpers and token reduction.** Words hold frog counts, so one proc reads them and another reduces them.

```nim
const flushBlockBytes = 1 shl 17
const sensibleMessage = "SensibleFrog Wins!."
const smartMessage = "SmartFrog Wins!."

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc countModulo(token: string, modulusValue: int64): int64 =
  var remainder: int64 = 0
  for charIndex in 0 .. token.len - 1:
    remainder = (remainder * 10 + int64(int(token[charIndex]) - 48)) mod modulusValue
  return remainder
```

Huge counts never become full integers.
The number reader handles only m, n and K.
Both readers share the same cursor.

**Buffered output.** Answers are collected into one block before writing.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each answer is one fixed message.
The buffer flushes after reaching the block size.

**Digit test and driver.** Row and column heaps are reduced, then tested in each binary place.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let moveLimit = nextInt(inputData, scanPos)
  let modulusValue = int64(moveLimit) + 1
  var rowHeaps = newSeq[int64](rowCount)
  var columnHeaps = newSeq[int64](columnCount)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let frogToken = nextToken(inputData, scanPos)
      let frogCount = countModulo(frogToken, modulusValue)
      rowHeaps[rowIndex] = (rowHeaps[rowIndex] + frogCount) mod modulusValue
      columnHeaps[columnIndex] = (columnHeaps[columnIndex] + frogCount) mod modulusValue
  var firstPlayerWins = false
  var digitWeight: int64 = 1
  let maximumCoordinate = max(rowCount, columnCount) - 1
  while digitWeight <= int64(maximumCoordinate):
    var digitTotal: int64 = 0
    for rowIndex in 0 .. rowCount - 1:
      let digitValue = (int64(rowIndex) div digitWeight) mod 2
      digitTotal += rowHeaps[rowIndex] * digitValue
      digitTotal = digitTotal mod modulusValue
    for columnIndex in 0 .. columnCount - 1:
      let digitValue = (int64(columnIndex) div digitWeight) mod 2
      digitTotal += columnHeaps[columnIndex] * digitValue
      digitTotal = digitTotal mod modulusValue
    if digitTotal mod modulusValue != 0:
      firstPlayerWins = true
    if digitWeight > int64(maximumCoordinate) div 2:
      break
    digitWeight *= 2
  if firstPlayerWins:
    appendOutput(sensibleMessage)
  else:
    appendOutput(smartMessage)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each count adds to one row heap and one column heap.
Binary places run up to the largest coordinate.
A single nonzero place decides the whole test.

## Complexity

Reading the grid and scanning binary places set the cost.

| phase | time | space |
|---|---|---|
| input read | one pass over the frog counts | one input string |
| heap totals | one reduction per cell | one heap per row and column |
| digit scan | O((m + n) log max(m, n)) | constant |
| output | one buffered line per test | block buffer |

The grid read dominates for large boards.

| measure | Big O |
|---|---|
| time | O(m times n plus (m + n) log max(m, n)) per test |
| space | O(m + n) per test |

Exploring every sequence of K orders grows without bound, while the digit test ignores K entirely. Reduce frog counts, scan binary places, and print the winner once.
