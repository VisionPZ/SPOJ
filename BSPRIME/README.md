# BSPRIME — Binary Sequence of Prime Number (SPOJ)

<https://www.spoj.com/problems/BSPRIME/>

## Problem

Write each prime in binary, concatenate the strings, and count the ones in the first N bits. Answer T such prefix queries.

The first input line gives T. Each following line gives one N. Print one count per line.

| item | bound |
|---|---|
| test count T | 1 to 50000 |
| prefix length N | 0 to 150000000 |
| sieve ceiling used | 110000000 |
| judge limit | 1000 ms, 1536 MB |

The binary forms have no leading zeros. The first few terms are 10, 11, 101, 111, so the stream starts 101110111.

Sample input:

```
3
3
10
50
```

Sample output:

```
2
8
36
```

## Idea

Treat the stream as a long tape and mark the running one counts at every prime boundary, like page numbers in a book. A binary search finds the last prime that fits wholly inside N, then a short prefix of the next prime finishes the count.

The sieve covers primes up to 110 million, which yields about 161.9 million bits and exceeds the largest query. Each prime contributes its bit length and its popcount to two prefix arrays. A query costs O(log π(L)); a fresh sieve per query would cost far more.

## Why It Works

1. Concatenation is ordered by prime value, so bit offsets are monotone.
2. `cumulativeBits[k]` stores the bits used by the first k primes.
3. `cumulativeOnes[k]` stores the ones used by the first k primes.
4. The largest k with `cumulativeBits[k] ≤ N` identifies the last complete prime.
5. The remaining N − `cumulativeBits[k]` bits come from the next prime, read from its most significant bit.

| term | meaning |
|---|---|
| `compositeFlags` | odd sieve flags; index i stands for 2i + 1 |
| `popcountTable` | one-byte lookup for counting bits |
| `cumulativeBits` | stream offset after each prime |
| `cumulativeOnes` | one count after each prime |
| `remainingBits` | partial length taken from the next prime |

For N = 10, the table shows the prefixes after the first few primes.

| prime | binary | cumulative bits | cumulative ones |
|---|---|---|---|
| 2 | 10 | 2 | 1 |
| 3 | 11 | 4 | 3 |
| 5 | 101 | 7 | 5 |
| 7 | 111 | 10 | 8 |

`cumulativeBits` and `cumulativeOnes` use `int32` because their largest values fit in 32 bits. `popcountTable` avoids a second inner loop for each prime.

## Code

**Input and buffer.** The reader stores all queries before the sieve starts, so the sieve runs once.

```nim
import math

const flushBlockBytes = 1 shl 17
const sieveLimit = 110000000
const tableBits = 16

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var queryValues = newSeq[int](caseCount)
for caseIndex in 0 .. caseCount - 1:
  queryValues[caseIndex] = nextInt(inputData, scanPos)
```

All queries are nonnegative, so the scanner needs no minus branch.
`appendOutput` flushes after `flushBlockBytes` bytes.
Reading first keeps the sieve work independent of query order.

**Sieve and prefix arrays.** An odd-only sieve produces the primes and their running totals.

```nim
var popcountTable = newSeq[int](1 shl tableBits)
for tableIndex in 1 .. (1 shl tableBits) - 1:
  popcountTable[tableIndex] = popcountTable[tableIndex div 2] + (tableIndex and 1)

var compositeFlags = newSeq[bool](sieveLimit div 2 + 1)
let rootValue = int(sqrt(float(sieveLimit))) + 1
var rootIndex = 1
while 2 * rootIndex + 1 <= rootValue:
  rootIndex += 1

var primeValues = newSeq[int32](1)
primeValues[0] = 2'i32
var cumulativeBits = newSeq[int32](2)
cumulativeBits[0] = 0'i32
cumulativeBits[1] = 2'i32
var cumulativeOnes = newSeq[int32](2)
cumulativeOnes[0] = 0'i32
cumulativeOnes[1] = 1'i32
var currentBitLength = 2
var nextBitBoundary = 4
var bitsSoFar: int32 = 2
var onesSoFar: int32 = 1

for index in 1 .. sieveLimit div 2:
  if compositeFlags[index]:
    continue
  let primeValue = 2 * index + 1
  var multipleIndex = (primeValue * primeValue) div 2
  while multipleIndex <= sieveLimit div 2:
    compositeFlags[multipleIndex] = true
    multipleIndex += primeValue
  if primeValue >= nextBitBoundary:
    currentBitLength += 1
    nextBitBoundary = 1 shl currentBitLength
  let onesInPrime = popcountTable[primeValue and ((1 shl tableBits) - 1)] +
                    popcountTable[primeValue shr tableBits]
  bitsSoFar += int32(currentBitLength)
  onesSoFar += int32(onesInPrime)
  primeValues.add int32(primeValue)
  cumulativeBits.add bitsSoFar
  cumulativeOnes.add onesSoFar
```

Index i of `compositeFlags` stands for the odd number 2i + 1.
`currentBitLength` tracks binary width without a logarithm per prime.
The two prefix arrays hold one entry per prime plus a zero entry.

**Query loop.** Each query finds its last full prime, then reads a partial prefix.

```nim
let primeCount = cumulativeBits.len - 1
for caseIndex in 0 .. caseCount - 1:
  let targetBits = queryValues[caseIndex]
  var lowIndex = 0
  var highIndex = primeCount
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex + 1) div 2
    if int(cumulativeBits[middleIndex]) <= targetBits:
      lowIndex = middleIndex
    else:
      highIndex = middleIndex - 1
  var answerValue = int(cumulativeOnes[lowIndex])
  var remainingBits = targetBits - int(cumulativeBits[lowIndex])
  if remainingBits > 0:
    let nextPrime = int(primeValues[lowIndex])
    var valueBits = 0
    var scanValue = nextPrime
    while scanValue > 0:
      valueBits += 1
      scanValue = scanValue shr 1
    var shiftCount = valueBits - 1
    while remainingBits > 0 and shiftCount >= 0:
      if ((nextPrime shr shiftCount) and 1) != 0:
        answerValue += 1
      shiftCount -= 1
      remainingBits -= 1
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Binary search uses the upper midpoint to keep progress.
`remainingBits` is zero when N ends on a prime boundary.
The final shift loop reads bits from the most significant side.

## Complexity

The sieve and prefix build run once; queries only search the prefix table.

| phase | time | space |
|---|---|---|
| input read | one pass over T values | one input string |
| odd sieve | O(L log log L) for L = 110000000 | L/2 flags |
| prefix build | O(π(L)) | three arrays of π(L) entries |
| each query | O(log π(L)) plus a short bit walk | none extra |
| output | T lines | block buffer |

| measure | Big O |
|---|---|
| time | O(L log log L + T log π(L)) |
| space | O(L) for sieve flags |

Rebuilding the stream for each query would cost O(T · N) and repeat the same primes. One shared prefix table removes that work.
