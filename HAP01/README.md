# HAP01 — Play with Binary Numbers (SPOJ)

<https://www.spoj.com/problems/HAP01/>

## Problem

Count the integers in a range whose binary ones sit almost equally often in alternating bit positions. The two counts are compared by absolute difference.

Input starts with T, then T lines holding M, N, and K. Print how many values between M and N have an absolute count difference of K.

| item | bound |
|---|---|
| test count T | 1 to 50 |
| range ends M, N | 1 to 10000000000000000000 |
| range width | at most 1000000 |
| target difference K | 0 to 50 |
| judge limit | 1201 ms, 1536 MB |

The range width limits brute iteration, and the large end values demand unsigned parsing.

Sample input:

```
1
1 10 2
```

Sample output:

```
2
```

## Idea

Alternating positions act like counting coins in even and odd slots, like sorting coins into two jars. Counting from the left flips the two jars when the bit length changes parity, but the absolute difference stays the same. A small table stores that difference for every 22-bit chunk, and three lookups give the difference for any 64-bit number.

## Why It Works

1. Number bit positions from zero at the least significant end.
2. Let E be ones at even positions and O be ones at odd positions.
3. A binary number with an even bit length swaps E and O relative to counting from the left.
4. The absolute difference equals |E - O| in both counting directions.
5. For a value v, the lowest bit contributes one to E and the rest swap parity, so gap(v) = (v and 1) - gap(v shifted right by one).
6. Chunks of 22 bits keep their parity after a shift, because 22 is even, so chunk gaps add.

| term | meaning |
|---|---|
| `parityTable` | signed even-minus-odd count for each 22-bit chunk |
| `chunkBits` | number of bits in one chunk |
| `currentNumber` | value being tested in the range loop |
| `matchingCount` | values that meet the target gap |

The table recurrence builds all chunk gaps in one linear pass.

```
gap(19) = gap(0b10011) = (even ones 2) - (odd ones 1) = 1
19 is binary 10011, and counting from the left gives 2 and 1
the absolute gap is 1 in both directions
```

The example confirms the parity swap does not change the answer.

## Code

**Input and table build.** Signed and unsigned scanners read the test data, and one table holds every chunk gap.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const chunkBits = 22
const chunkMask = 4194303

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextUint(data: string, pos: var int): uint64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: uint64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * uint64(10) + uint64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The unsigned scanner holds range ends up to ten to the nineteenth power.
The signed scanner reads the test count and the target gap.
One output buffer serves all cases.

**Chunk lookup and counting.** Three table reads give the gap of each value in the range.

```nim
const tableSize = 1 shl chunkBits
var parityTable = newSeq[int16](tableSize)
var tableIndex = 1
while tableIndex < tableSize:
  parityTable[tableIndex] = int16(tableIndex and 1) - parityTable[tableIndex shr 1]
  tableIndex += 1

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let lowerBound = nextUint(inputData, scanPos)
  let upperBound = nextUint(inputData, scanPos)
  let targetGap = nextInt(inputData, scanPos)
  var matchingCount = 0
  var currentNumber = lowerBound
  while currentNumber <= upperBound:
    let firstChunk = parityTable[int(currentNumber and uint64(chunkMask))]
    let secondChunk = parityTable[int((currentNumber shr chunkBits) and uint64(chunkMask))]
    let thirdChunk = parityTable[int(currentNumber shr (2 * chunkBits))]
    let parityGap = firstChunk + secondChunk + thirdChunk
    let absoluteGap = if parityGap < 0: -parityGap else: parityGap
    if absoluteGap == targetGap:
      matchingCount += 1
    currentNumber += 1
  appendOutput($matchingCount)
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

The table index runs from one, and the gap at zero stays zero.
Three chunks cover all 64 bits of any unsigned value.
The sign of the gap is dropped before comparison with K.

## Complexity

The table is shared, and each range value costs three reads.

| phase | time | space |
|---|---|---|
| input read | one pass over T cases | one input string |
| table build | one pass over four million chunks | one int16 array |
| each value | three table reads and one compare | constant |
| output | one line per case | block buffer |

The range loop is the only part that scales with the input width.

| measure | Big O |
|---|---|
| time | O(table size plus N minus M summed over cases) |
| space | O(table size) |

Scanning every bit of every value would cost 64 times as much per number, while chunk lookup costs three reads.
