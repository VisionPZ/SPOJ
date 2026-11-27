# BSPRIME — Binary Sequence of Prime Number (SPOJ)

<https://www.spoj.com/problems/BSPRIME/>

## Problem

Write each prime in binary without leading zeros, concatenate the bit strings, and count the 1-bits in the first N bits. Answer T such prefix queries.

The first input line gives T. Each following line gives one prefix length N. Print one count per line.

The constraints and judge limits:

| item | bound |
|---|---|
| test count T | 1 to 50000 |
| prefix length N | 0 to 150000000 |
| sieve ceiling used | 110000000 |
| judge limit | 1000 ms, 1536 MB |

Primes up to 110 million produce about 161.9 million bits, covering the maximum query.

Sample input and output:

```
3
3
10
50
```

```
2
8
36
```

The stream starts `10` (2), `11` (3), `101` (5), `111` (7), giving 2 ones in the first 3 bits and 8 ones in the first 10 bits.

## Idea

Treat the stream as a long tape and mark the running one counts at every prime boundary, like page numbers in a book. A binary search finds the last prime that fits inside N, then a short bit scan of the next prime finishes the count.

A bit-packed odd sieve (one bit per odd integer inside 64-bit words) finds all primes up to 110 million in under 7 MB of memory. Each prime adds its bit width and popcount to two 32-bit prefix arrays. Each query costs O(log π(L)); rescanning primes per query would cost O(T · L).

One shared bit-packed sieve and two prefix arrays answer all 50,000 queries in milliseconds.

## Why It Works

1. Primes appear in increasing order, so cumulative bit offsets are strictly increasing.
2. `cumulativeBits[k]` stores the total bits emitted by the first k primes.
3. `cumulativeOnes[k]` stores the total 1-bits emitted by the first k primes.
4. The largest k with `cumulativeBits[k] ≤ N` identifies the last complete prime.
5. The remaining `N - cumulativeBits[k]` bits come from the most significant bits of `primeValues[k]`.

The main terms used in the program:

| term | meaning |
|---|---|
| `compositeBits` | bit-packed odd sieve; bit `index` stands for `2 * index + 1` |
| `popcountTable` | 16-bit lookup table of bit counts |
| `cumulativeBits` | stream bit offset after each prime |
| `cumulativeOnes` | cumulative 1-bit count after each prime |
| `remainingBits` | partial bit count taken from the next prime |

Packing 64 odd numbers per `uint64` word shrinks the sieve array by 8x so it stays cache-friendly.

Worked prefix table for N = 10:

| prime | binary | cumulative bits | cumulative ones |
|---|---|---|---|
| 2 | 10 | 2 | 1 |
| 3 | 11 | 4 | 3 |
| 5 | 101 | 7 | 5 |
| 7 | 111 | 10 | 8 |

At N = 10, binary search lands on prime 7 with `remainingBits = 0` and returns 8.

## Code

**Input and buffer.** The reader loads all queries once so the sieve runs only once.

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

All queries are non-negative, so `nextInt` needs no sign branch.
`appendOutput` flushes in 128 KiB blocks.
Storing queries first keeps input parsing separate from the sieve.

**Bit-packed odd sieve and prefix arrays.** One bit per odd number marks composites up to `sieveLimit`, then one pass builds the prefix arrays.

```nim
var popcountTable = newSeq[uint8](1 shl tableBits)
for tableIndex in 1 .. (1 shl tableBits) - 1:
  popcountTable[tableIndex] = popcountTable[tableIndex shr 1] + uint8(tableIndex and 1)

let halfLimit = sieveLimit div 2
var compositeBits = newSeq[uint64]((halfLimit shr 6) + 1)
let rootValue = int(sqrt(float(sieveLimit))) + 1
let rootHalf = rootValue div 2

for index in 1 .. rootHalf:
  if (compositeBits[index shr 6] and (1'u64 shl (index and 63))) == 0'u64:
    let primeValue = 2 * index + 1
    var multipleIndex = (primeValue * primeValue) shr 1
    while multipleIndex <= halfLimit:
      compositeBits[multipleIndex shr 6] = compositeBits[multipleIndex shr 6] or (1'u64 shl (multipleIndex and 63))
      multipleIndex += primeValue

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

for index in 1 .. halfLimit:
  if (compositeBits[index shr 6] and (1'u64 shl (index and 63))) != 0'u64:
    continue
  let primeValue = 2 * index + 1
  if primeValue >= nextBitBoundary:
    currentBitLength += 1
    nextBitBoundary = 1 shl currentBitLength
  let onesInPrime = int(popcountTable[primeValue and ((1 shl tableBits) - 1)]) +
                    int(popcountTable[primeValue shr tableBits])
  bitsSoFar += int32(currentBitLength)
  onesSoFar += int32(onesInPrime)
  primeValues.add int32(primeValue)
  cumulativeBits.add bitsSoFar
  cumulativeOnes.add onesSoFar
```

Bit `index` in `compositeBits` represents the odd number `2 * index + 1`, using 6.8 MB instead of 55 MB.
Only primes up to `sqrt(sieveLimit)` mark multiples, and `currentBitLength` tracks binary width without logarithms.
Two lookups in `popcountTable` count all set bits of each 27-bit prime in O(1).

**Query loop.** Binary search locates the last full prime, and a short shift loop handles any leftover bits.

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

Upper midpoint `(lowIndex + highIndex + 1) div 2` avoids an infinite loop when `lowIndex + 1 == highIndex`.
When `remainingBits` is zero, the answer comes straight from `cumulativeOnes`.
The final write flushes all remaining output lines.

## Complexity

The bit-packed sieve and prefix arrays run once; each query does one binary search.

| phase | time | space |
|---|---|---|
| input read | one pass over T queries | one input string |
| bit-packed odd sieve | O(L log log L) for L = 110000000 | L / 16 bytes (~6.8 MB) |
| prefix build | O(π(L)) | three `int32` arrays of π(L) entries |
| each query | O(log π(L)) plus at most 27 bit checks | O(1) |
| output write | T lines | one 128 KiB buffer |

Packing the sieve into bits reduces sieve memory by 8x while keeping prefix arrays compact.

| measure | Big O |
|---|---|
| time | O(L log log L + T log π(L)) |
| space | O(L / 16 + π(L)) |

Rebuilding the prime bit stream per query would cost O(T · N), whereas one shared prefix table answers every query in logarithmic time.
