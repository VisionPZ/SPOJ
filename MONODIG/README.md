## Problem

Each case gives a digit K and up to ten numbers. For each number, print the shortest length of a K-representation, or NO when that length exceeds eight. A K-representation is an expression built from K, KK, KKK, and so on, using addition, subtraction, multiplication, and exact division.

The judge bounds are:

| Quantity | Bound |
| --- | --- |
| Digit K | 1 to 9 |
| Numbers per case | 1 to 10 |
| Query value | 1 to 32000 |
| Length limit | 8 |
| Time limit | 1647 ms |
| Memory limit | 1536 MB |

The length limit and the small value range let one precomputation serve every query.

## Idea

Build one answer table per digit before reading the queries. Each table stores the shortest digit count for every value up to 32000. Combine values of two shorter counts with the four operations to fill the next count. A query then reads one cell from the prepared table.

One generated value costs a few hash probes. One query costs one array read.

## Why It Works

Every expression has a root operator joining two smaller expressions. The root adds their digit counts. A shorter expression for the same value never raises the total count, so one count per value is enough.

The program walks total counts from two to eight. For each total, it splits the count into leftLength and rightLength. Both operand buckets are complete before the program reads them.

The marking rules are:

- `repdigit = repdigit * 10 + digit` builds K, KK, and so on, at lengths 1 to 8.
- `rightLength = totalLength - leftLength` pairs the two operand lengths.
- `noteValue(leftValue + rightValue)` records a result at cost totalLength.
- `if rightValue != 0 and leftValue mod rightValue == 0` guards exact division.

The generator also produces the reachable values below, listed up to 100:

```
length 1: [5]
  12 present at length 1? False
length 2: [0, 1, 10, 25, 55]
  12 present at length 2? False
length 3: [0, 2, 4, 5, 6, 11, 15, 20, 30, 50, 60]
  12 present at length 3? False
length 4: [0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 15, 16, 20, 24, 25, 26, 30, 35, 45, 50, 54, 55, 56, 65, 75, 80, 100]
  12 present at length 4? True
```

The value 12 first appears at length 4, from (55+5)/5.

## Code

```nim
const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  maxRepresentationLength = 8
  maxQueryValue = 32000
  hashCapacity = 1 shl 16
  hashMultiplier = 1103515245

const readChunkBytes = 1 shl 20

var inputData = newString(readChunkBytes)
var filledBytes = 0
while true:
  if filledBytes + readChunkBytes > inputData.len:
    inputData.setLen(inputData.len + readChunkBytes)
  let bytesRead = stdin.readBuffer(addr inputData[filledBytes], readChunkBytes)
  if bytesRead <= 0: break
  filledBytes += bytesRead
inputData.setLen(filledBytes)

var scanPos = 0
```

The loop grows the buffer while bytes remain. `setLen(filledBytes)` removes unused bytes before scanning. One bulk read pass handles the whole input.

```nim
proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips blanks between cases and builds each value by hand. It ignores minus signs because the spec lists positive values only. The output buffer flushes in blocks, never per number.

```nim
type
  LengthTable = object
    occupied: seq[bool]
    keys: seq[int]
    lengths: seq[int]

proc newLengthTable(): LengthTable =
  result.occupied = newSeq[bool](hashCapacity)
  result.keys = newSeq[int](hashCapacity)
  result.lengths = newSeq[int](hashCapacity)

proc clearLengthTable(table: var LengthTable) =
  for i in 0..<hashCapacity:
    table.occupied[i] = false

proc slotFor(key: int): int =
  var magnitude = key
  if magnitude < 0: magnitude = -magnitude
  return (magnitude * hashMultiplier) and (hashCapacity - 1)

proc getLength(table: var LengthTable, key: int): int =
  var slot = slotFor(key)
  while table.occupied[slot]:
    if table.keys[slot] == key: return table.lengths[slot]
    slot = (slot + 1) and (hashCapacity - 1)
  return 0

proc putLength(table: var LengthTable, key, value: int) =
  var slot = slotFor(key)
  while table.occupied[slot]:
    if table.keys[slot] == key:
      table.lengths[slot] = value
      return
    slot = (slot + 1) and (hashCapacity - 1)
  table.occupied[slot] = true
  table.keys[slot] = key
  table.lengths[slot] = value
```

Linear probing fixes the hash collision by moving to the next slot. The table keeps negative values from subtraction. All probes stay inside 65536 slots.

```nim
var lengthTable = newLengthTable()
var valueBuckets: array[maxRepresentationLength + 1, seq[int]]
var currentTotal = 0

proc noteValue(value: int) =
  let existing = getLength(lengthTable, value)
  if existing == 0 or existing > currentTotal:
    putLength(lengthTable, value, currentTotal)
    valueBuckets[currentTotal].add value

proc buildAnswers(digit: int): seq[int] =
  clearLengthTable(lengthTable)
  for i in 0..maxRepresentationLength:
    valueBuckets[i].setLen 0
  var repdigit = 0
  for i in 1..maxRepresentationLength:
    repdigit = repdigit * 10 + digit
    putLength(lengthTable, repdigit, i)
    valueBuckets[i].add repdigit
  for totalLength in 2..maxRepresentationLength:
    currentTotal = totalLength
    for leftLength in 1..<totalLength:
      let rightLength = totalLength - leftLength
      for leftValue in valueBuckets[leftLength]:
        if getLength(lengthTable, leftValue) != leftLength: continue
        for rightValue in valueBuckets[rightLength]:
          if getLength(lengthTable, rightValue) != rightLength: continue
          noteValue(leftValue + rightValue)
          noteValue(leftValue - rightValue)
          noteValue(leftValue * rightValue)
          if rightValue != 0 and leftValue mod rightValue == 0:
            noteValue(leftValue div rightValue)
  result = newSeq[int](maxQueryValue + 1)
  for value in 1..maxQueryValue:
    result[value] = getLength(lengthTable, value)
```

The total loop runs from 2 to 8. Its split always uses two shorter buckets, so a bucket is complete before the program reads it. Division runs only on exact multiples.

```nim
var answers: array[10, seq[int]]
for digit in 1..9:
  answers[digit] = buildAnswers(digit)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let digit = nextInt(inputData, scanPos)
  let numberCount = nextInt(inputData, scanPos)
  let answerRow = answers[digit]
  for j in 0..<numberCount:
    let queryValue = nextInt(inputData, scanPos)
    let representationLength = answerRow[queryValue]
    if representationLength == 0:
      appendOutput("NO\n")
    else:
      appendOutput($representationLength)
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Nine digits are prepared once, before the first query. A zero length means NO because the search stopped at eight. The final write flushes the remaining block.

## Complexity

Costs by phase:

| Phase | Time | Space |
| --- | --- | --- |
| Precompute | O(9 · 85000 combinations) | O(65536 slots + 9500 values) |
| Query loop | O(number of queries) | O(32001 cells per digit) |

Big O is O(9C + Q) time and O(9V + H) space, where C counts combinations per digit and Q counts queries. Naive expression-tree enumeration grows exponentially with the length limit.
