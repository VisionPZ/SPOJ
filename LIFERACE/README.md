# LIFERACE — LIFE IS A RACE (SPOJ)
<https://www.spoj.com/problems/LIFERACE/>

## Problem

Person number n has intelligence S[n], where S is the nondecreasing sequence in which each value n occurs S[n] times. Good-hearted person j is person j³. Process range additions over these persons and answer range sums of their intelligence.

Input starts with x and y. The next x lines give L, R, I and add I to every good-hearted person from L through R. The next y lines give L, R and ask for the sum over that range. When L exceeds R, treat the range as reversed.

| item | bound |
|---|---|
| updates x | up to 100000 |
| queries y | up to 100000 |
| person index | 1 to 999999 |
| increment I | up to 10 |
| largest cube | 999999³ |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
1 1
1 1 1
1 2
```

Sample output:

```
6
```

## Idea

Repeated values form blocks, like stacked crates whose heights equal their labels. S is Golomb's sequence, and the block ends follow S(k) = sum of S[i] for i up to k. Summing one level higher gives P(k) = sum of i × S[i], which reaches the largest cube after about ten million terms. A sweep locates each cube inside one block, and two Fenwick trees handle the range additions and range sums. The takeaway is to build the block table once and answer each query in logarithmic time.

## Why It Works

1. Value i occupies S[i] consecutive positions, so positions 1 through S(k) hold exactly the values up to k.
2. Let S(k) be the prefix sum of Golomb terms and P(k) the prefix sum of i × S[i].
3. If P(k−1) < x ≤ P(k), then S[x] equals S(k−1) plus the ceiling of (x − P(k−1))/k.
4. The cubes 1³, 2³, … increase, so one forward sweep answers all base lookups.
5. A difference pair of Fenwick trees turns range adds into prefix sums of increments.

| term | meaning |
|---|---|
| `golombTable` | Golomb values indexed by position |
| `productTotal` | running P(k) while building the table |
| `blockIndex` | block number k during the cube sweep |
| `bitOne` and `bitTwo` | Fenwick trees for range adds |

A script generated these block lookups:

| j | j³ | S[j³] |
|---|---|---|
| 1 | 1 | 1 |
| 2 | 8 | 4 |
| 3 | 27 | 9 |
| 1000 | 1000000000 | 86 |

The sample adds one to person one, so S[1] + S[8] + 1 equals six.

## Code

**Input and table build.** The scanner reads all tokens, then Mallows' recurrence fills the Golomb table until P(k) passes the largest cube.

```nim
const flushBlockBytes = 1 shl 17
const maxPersonIndex = 999999
const maxCubePosition: int64 = 999999'i64 * 999999'i64 * 999999'i64
const tableCapacity = 11000000

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

var golombTable = newSeq[uint32](tableCapacity)
golombTable[0] = 0'u32
golombTable[1] = 1'u32
var tableIndex = 1
var productTotal: int64 = 1
while productTotal < maxCubePosition:
  tableIndex += 1
  let previousValue = golombTable[tableIndex - 1]
  let nestedValue = golombTable[int(previousValue)]
  let targetIndex = tableIndex - int(nestedValue)
  let currentValue = 1'u32 + golombTable[targetIndex]
  golombTable[tableIndex] = currentValue
  productTotal += int64(tableIndex) * int64(currentValue)
```

Every new term reads earlier entries only.
The product sum fits in a signed 64-bit integer.
The preallocated table avoids repeated resizing.

**Base intelligence.** The cube sweep keeps the current block and its two prefix sums.

```nim
var baseValues = newSeq[int64](maxPersonIndex + 1)
var prefixBase = newSeq[int64](maxPersonIndex + 1)
var blockIndex = 1
var sumTerms: int64 = 1
var productTerms: int64 = 1
var previousSum: int64 = 0
var previousProduct: int64 = 0
for personIndex in 1 .. maxPersonIndex:
  let cubePosition = int64(personIndex) * int64(personIndex) * int64(personIndex)
  while productTerms < cubePosition:
    blockIndex += 1
    previousSum = sumTerms
    previousProduct = productTerms
    let golombValue = int64(golombTable[blockIndex])
    sumTerms += golombValue
    productTerms += int64(blockIndex) * golombValue
  let offsetValue = (cubePosition - previousProduct + int64(blockIndex) - 1) div int64(blockIndex)
  baseValues[personIndex] = previousSum + offsetValue
  prefixBase[personIndex] = prefixBase[personIndex - 1] + baseValues[personIndex]
```

The block index only moves forward.
The ceiling uses integer division with a raised numerator.
Prefix sums answer any base range in constant time.

**Increments and queries.** Two Fenwick trees turn each update into four point changes.

```nim
var bitOne = newSeq[int64](maxPersonIndex + 2)
var bitTwo = newSeq[int64](maxPersonIndex + 2)

proc bitAdd(bitValues: var seq[int64], indexValue: int, deltaValue: int64) =
  var cursor = indexValue
  while cursor <= maxPersonIndex + 1:
    bitValues[cursor] += deltaValue
    cursor += cursor and -cursor

proc bitPrefix(bitValues: seq[int64], indexValue: int): int64 =
  var cursor = indexValue
  result = 0'i64
  while cursor > 0:
    result += bitValues[cursor]
    cursor -= cursor and -cursor

proc addRange(leftIndex: int, rightIndex: int, incrementValue: int64) =
  bitAdd(bitOne, leftIndex, incrementValue)
  bitAdd(bitOne, rightIndex + 1, -incrementValue)
  bitAdd(bitTwo, leftIndex, incrementValue * int64(leftIndex - 1))
  bitAdd(bitTwo, rightIndex + 1, -incrementValue * int64(rightIndex))

proc prefixIncrement(indexValue: int): int64 =
  bitPrefix(bitOne, indexValue) * int64(indexValue) - bitPrefix(bitTwo, indexValue)

let updateCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
for updateIndex in 0 .. updateCount - 1:
  var leftIndex = nextInt(inputData, scanPos)
  var rightIndex = nextInt(inputData, scanPos)
  let incrementValue = int64(nextInt(inputData, scanPos))
  if leftIndex > rightIndex:
    let swapIndex = leftIndex
    leftIndex = rightIndex
    rightIndex = swapIndex
  addRange(leftIndex, rightIndex, incrementValue)
for queryIndex in 0 .. queryCount - 1:
  var leftIndex = nextInt(inputData, scanPos)
  var rightIndex = nextInt(inputData, scanPos)
  if leftIndex > rightIndex:
    let swapIndex = leftIndex
    leftIndex = rightIndex
    rightIndex = swapIndex
  let baseTotal = prefixBase[rightIndex] - prefixBase[leftIndex - 1]
  let addedTotal = prefixIncrement(rightIndex) - prefixIncrement(leftIndex - 1)
  appendOutput($(baseTotal + addedTotal))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Reversed ranges are swapped before any update.
The two tree prefix formulas combine to a range sum.
One buffer flush closes the output.

## Complexity

The table has about 10.1 million entries for the largest cube.

| phase | time | space |
|---|---|---|
| table build | one step per entry | 11 million 32-bit terms |
| cube sweep | one block advance per cube | two prefix sums |
| updates | four Fenwick writes each | two index arrays |
| queries | four Fenwick reads each | output block buffer |

The bounds count work per operation after the build.

| measure | Big O |
|---|---|
| table build | O(K), K about 10000000 |
| cube sweep | O(10⁶ + K) total |
| update or query | O(log 10⁶) |

Generating the sequence up to the largest cube would need about 10¹¹ terms.
The takeaway is that summing one level higher shrinks the table to a workable size.
