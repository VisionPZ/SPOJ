# MONODIG — Monodigital Representations (SPOJ)
<https://www.spoj.com/problems/MONODIG/>

## Problem

Expressions may use only numbers made from one repeated digit K, plus arithmetic. For each query number, find the shortest representation using at most eight copies of K.

The input starts with the case count. Each case gives a digit and a list of target numbers. Print the shortest representation length, or `NO`.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Digit `K` | 1 to 9 |
| Numbers per case | 1 to 10 |
| Target value | 1 to 32000 |
| Maximum length | 8 digits |
| Judge time | 1647 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

One precomputation per digit serves every query.

Sample input and output:

Input:

```
1
5
2
12
31168
```

Output:

```
4
NO
```

## Idea

Precompute every short expression once per digit. Think of a table that lists every value reachable with at most eight copies of that digit.

The program grows values by total digit count. It combines two shorter values with addition, subtraction, multiplication, or exact division. A hash table (a key-to-value lookup) keeps the shortest length seen. Each query then costs one lookup. Searching expressions per query would repeat the same work.

Takeaway: one shared table turns queries into constant-time lookups.

## Why It Works

Every expression tree splits at its last operator.

1. The leaves are repdigits such as 5, 55, and 555.
2. A root operator joins two subexpressions whose lengths add.
3. Buckets group values by their exact digit count.
4. `noteValue` keeps only the smallest length for a value.
5. Division runs only when the remainder is zero.

The terms are:

| Term | Meaning |
| --- | --- |
| `repdigit` | A number made of one repeated digit |
| `valueBuckets` | Values grouped by digit count |
| `lengthTable` | Hash table of shortest lengths |
| `currentTotal` | Digit count of the expression being built |

Length order ensures the first entry is minimal.

A script checked digit 5 against sample values:

| Value | Expression | Length |
| --- | --- | --- |
| 5 | `5` | 1 |
| 10 | `5 + 5` | 2 |
| 11 | `55 / 5` | 3 |
| 12 | `(55 + 5) / 5` | 4 |
| 31168 | none within eight digits | NO |

The sample answers match the table.

## Code

**Constants and bulk input.**

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
```

A one-megabyte chunk fills the input buffer. The capacity doubles until the stream ends. One read pass handles all cases.

**Integer scanner and output helper.**

```nim
var scanPos = 0

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

The scanner skips separators and reads digits in place. Output collects in a buffer and flushes in blocks.

**Length hash table.**

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

Open addressing keeps lookups fast. `slotFor` mixes the key and masks it to the capacity. Linear probing resolves collisions.

**Value recording.**

```nim
var valueBuckets: array[maxRepresentationLength + 1, seq[int]]
var currentTotal = 0

proc noteValue(value: int) =
  let existing = getLength(lengthTable, value)
  if existing == 0 or existing > currentTotal:
    putLength(lengthTable, value, currentTotal)
    valueBuckets[currentTotal].add value
```

A value is recorded only when its length improves. The matching bucket then gains that value.

**Expression build and precompute.**

```nim
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

var answers: array[10, seq[int]]
for digit in 1..9:
  answers[digit] = buildAnswers(digit)
```

Buckets combine in increasing total length. Each pair contributes four operations. The last loop copies answers into a flat table per digit.

**Query loop.**

```nim
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

Each query reads one value and prints its row entry. Zero means `NO`. The final write flushes pending text.

## Complexity

Precomputation dominates the runtime.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total digits) | O(Input size) |
| Precompute | O(9 * B^3) | O(32000) |
| Queries | O(1) each | O(32000 * 9) |
| Output | O(Total queries) | O(1) |

B is the bucket size at length eight.

| Measure | Bound |
| --- | --- |
| Time | O(9 * B^3) once, then O(1) per query |
| Space | O(Hash capacity + answer rows) |

Every query reuses the same nine tables.

Building expressions separately for each query would repeat millions of combinations.
