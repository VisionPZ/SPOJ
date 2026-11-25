# NTG — NT Games (SPOJ)

<https://www.spoj.com/problems/NTG/>

## Problem

For each query with bounds l and r, add up gcd(i, j) raised to k over all i from 1 to j, for every j from l to r. Report the total modulo 1000000007.

Input gives k, then a query count, then one pair l r per query. Output one total per query in the same order.

| item | bound |
|---|---|
| exponent k | 1 to 100000 |
| queries t | 1 to 100000 |
| query bounds l, r | 1 to 100000 with l ≤ r |
| judge limit | 500 ms, 1536 MB |

The query bound of 100000 allows one table over all possible upper endpoints.

Sample input:

```
1
1
1 5
```

The sample asks one query with k = 1 over the range 1 to 5.

Sample output:

```
26
```

The five inner sums are 1, 3, 5, 8 and 9.

## Idea

Replacing each inner sum by divisor contributions is like counting coins by denomination instead of weighing each pile again. For a fixed upper endpoint j, numbers i with gcd(i, j) equal to d match the totient of j divided by d. That gives an inner sum over divisors of j. Build all inner sums once, prefix them, and answer each query by subtraction. Each divisor pass costs one modular multiply, while a direct gcd loop costs one step for every pair in every query. Count divisors, then subtract prefixes.

## Why It Works

1. For a divisor d of j, exactly totient(j/d) values i in 1..j satisfy gcd(i, j) = d.
2. The inner sum for j is therefore the sum of d^k times totient(j/d) over all divisors d of j.
3. Adding inner sums for j = 1..m gives a prefix total for m.
4. The answer for l..r is the prefix at r minus the prefix at l - 1, modulo 1000000007.

| term | meaning |
|---|---|
| `totientValues` | Euler totient of each value up to the largest right bound |
| `primePowerValues` | d^k modulo the modulus for each divisor d |
| `intervalTotals` | inner sum for each upper endpoint j |
| `prefixTotals` | running total of inner sums up to each j |

The four arrays turn one divisor identity into constant-time queries.

A script trace of the sample with k = 1:

```
j       1  2  3  4  5
inner   1  3  5  8  9
prefix  1  4  9 17 26
```

At j = 4, divisors 1, 2 and 4 contribute 1*2, 2*1 and 4*1, which total 8.

## Code

**Input and modular power.** The reader stores queries so the table can stop at the largest right bound.

```nim
const flushBlockBytes = 1 shl 17
const moduloBase = 1000000007'i64

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

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  result = 1'i64
  var currentBase = baseValue mod moduloBase
  var remainingExponent = exponentValue
  while remainingExponent > 0'i64:
    if (remainingExponent and 1'i64) == 1'i64:
      result = result * currentBase mod moduloBase
    currentBase = currentBase * currentBase mod moduloBase
    remainingExponent = remainingExponent shr 1

let exponentK = int64(nextInt(inputData, scanPos))
let attackCount = nextInt(inputData, scanPos)
var queryLefts = newSeq[int](attackCount)
var queryRights = newSeq[int](attackCount)
var largestRight = 0
for attackIndex in 0 .. attackCount - 1:
  queryLefts[attackIndex] = nextInt(inputData, scanPos)
  queryRights[attackIndex] = nextInt(inputData, scanPos)
  if queryRights[attackIndex] > largestRight:
    largestRight = queryRights[attackIndex]
```

Exponentiation by squaring keeps the power step logarithmic.
Table size follows the largest right bound, not the query count.
The scanner reads every query before any table work starts.

**Totients, divisors and answers.** One sieve and one divisor sweep build the prefix table.

```nim
var totientValues = newSeq[int](largestRight + 1)
for valueIndex in 0 .. largestRight:
  totientValues[valueIndex] = valueIndex
for primeValue in 2 .. largestRight:
  if totientValues[primeValue] == primeValue:
    var multipleValue = primeValue
    while multipleValue <= largestRight:
      totientValues[multipleValue] = totientValues[multipleValue] div primeValue * (primeValue - 1)
      multipleValue += primeValue

var primePowerValues = newSeq[int64](largestRight + 1)
for baseValue in 1 .. largestRight:
  primePowerValues[baseValue] = powerMod(int64(baseValue), exponentK)

var intervalTotals = newSeq[int64](largestRight + 1)
for divisorValue in 1 .. largestRight:
  let divisorPower = primePowerValues[divisorValue]
  var quotientValue = 1
  while divisorValue * quotientValue <= largestRight:
    let targetIndex = divisorValue * quotientValue
    intervalTotals[targetIndex] = (intervalTotals[targetIndex] + divisorPower * int64(totientValues[quotientValue])) mod moduloBase
    quotientValue += 1

var prefixTotals = newSeq[int64](largestRight + 1)
for valueIndex in 1 .. largestRight:
  prefixTotals[valueIndex] = (prefixTotals[valueIndex - 1] + intervalTotals[valueIndex]) mod moduloBase

for attackIndex in 0 .. attackCount - 1:
  let leftBound = queryLefts[attackIndex]
  let rightBound = queryRights[attackIndex]
  var answerValue = prefixTotals[rightBound] - prefixTotals[leftBound - 1]
  if answerValue < 0'i64:
    answerValue += moduloBase
  appendOutput($answerValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sieve updates every multiple of each prime once.
The divisor sweep visits each pair (d, j/d) exactly once.
The subtraction adds the modulus once when it goes negative.

## Complexity

The table is shared by all queries, so query count only affects output size.

| phase | time | space |
|---|---|---|
| input read | one token scan | two query lists |
| totient sieve | one pass per prime multiple | one array |
| divisor sweep | one pass per divisor pair | two arrays |
| queries | one subtraction each | block buffer |

The divisor sweep is the largest phase at a right bound of 100000.

| measure | Big O |
|---|---|
| time | O(R log R + t) with R the largest right bound |
| space | O(R + t) |

A direct gcd loop over every pair of every query would multiply this cost by R. The shared prefix table answers each query in one step.
