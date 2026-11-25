# RLTHREE — Robert Langdon & The Rule of Three (SPOJ)

<https://www.spoj.com/problems/RLTHREE/>

## Problem

Three points sit at binary coordinates of an N-dimensional unit cube. Count cube vertices whose Manhattan distance to all three points is equal, modulo 1000000007.

Input has three binary strings of equal length, one per point. Output has one integer, the count modulo 1000000007.

| item | bound |
|---|---|
| dimension N | 2 to 100000 |
| coordinate bits | 0 or 1 |
| judge limit | 2000 ms, 1536 MB |

Manhattan distance between binary points equals the number of differing bits.

Sample input:

```
111
001
100
```

Sample output:

```
2
```

## Idea

Think of three runners on a ladder where each rung belongs to two of them and one outsider. Equal distances mean each outsider gets the same number of losing rungs. Counting coordinate patterns and summing one balance parameter makes the work linear, while a scan of all 2^N vertices cannot scale to N = 100000.

## Why It Works

1. At each coordinate, either all three bits agree or exactly one bit differs.
2. An agreeing coordinate adds the same distance to all three points, whichever bit the vertex uses, giving a factor of 2.
3. Let `minorityCounts` hold how often each point is the odd one out.
4. For a differing coordinate, let the signed value be +1 when the vertex picks the minority bit and -1 otherwise.
5. The difference between two point distances equals the difference of their signed sums.
6. Equal distances therefore require one common balance value across all three points.
7. A balance is legal when its absolute value fits every count and shares each count's parity.
8. For balance value L, point j picks (count[j] + L) / 2 minority bits, giving a product of binomials.

| term | meaning |
|---|---|
| `minorityCounts` | times each point holds the differing bit |
| `freePositions` | coordinates where all three bits agree |
| `balance` | common signed sum of the three groups |
| `factorial` | factorials used for binomial coefficients |
| `safeTotal` | running count of safe vertices modulo 1000000007 |

The balance must fit all three counts, so its range is limited by the smallest count.

A worked trace from `gen.py`:

```
strings 111, 001, 100
coordinates: point2 odd, point1 odd, point3 odd
counts = [1, 1, 1], free = 0
balance -1 -> choose 0 each -> 1 way
balance +1 -> choose 1 each -> 1 way
total = 2
```

The two ways are the vertices (1, 0, 1) and (0, 1, 0) from the statement.

## Code

**Binary reader and scanner.** The reader takes the whole input, then reads each string bit by bit.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const modulusValue: int64 = 1000000007
const exponentForInverse = 1000000005

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextBinaryString(data: string, pos: var int): string =
  while pos < data.len and data[pos] != '0' and data[pos] != '1':
    pos += 1
  var binaryText = ""
  while pos < data.len and (data[pos] == '0' or data[pos] == '1'):
    binaryText.add data[pos]
    pos += 1
  return binaryText
```

Line breaks and spaces are skipped automatically.
Each returned string contains only the characters 0 and 1.
Three calls consume the three points.

**Buffered output.** One string collects all written text and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

A single answer is appended once.
The block flush keeps the write path uniform across problems.
The final write clears any remaining text.

**Modular helpers.** Fast powering and factorials support binomial coefficients.

```nim
proc powerMod(baseValue, exponentValue: int64): int64 =
  var baseRemainder = baseValue mod modulusValue
  var exponentLeft = exponentValue
  var resultValue: int64 = 1
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      resultValue = (resultValue * baseRemainder) mod modulusValue
    baseRemainder = (baseRemainder * baseRemainder) mod modulusValue
    exponentLeft = exponentLeft div 2
  return resultValue

proc combination(totalCount, chooseCount: int, factorial, inverseFactorial: seq[int64]): int64 =
  if chooseCount < 0 or chooseCount > totalCount:
    return 0
  let firstProduct = (factorial[totalCount] * inverseFactorial[chooseCount]) mod modulusValue
  return (firstProduct * inverseFactorial[totalCount - chooseCount]) mod modulusValue
```

Fermat powering gives the inverse factorial table.
Each product stays in 64 bits before the modulus is applied.
Out-of-range choices return zero.

**Pattern counting.** Each coordinate is classified, then balances are summed.

```nim
let firstHound = nextBinaryString(inputData, scanPos)
let secondHound = nextBinaryString(inputData, scanPos)
let thirdHound = nextBinaryString(inputData, scanPos)
let dimension = firstHound.len
var minorityCounts = newSeq[int](3)
var freePositions = 0
for position in 0 .. dimension - 1:
  let firstBit = int(firstHound[position]) - firstDigitValue
  let secondBit = int(secondHound[position]) - firstDigitValue
  let thirdBit = int(thirdHound[position]) - firstDigitValue
  if firstBit == secondBit and secondBit == thirdBit:
    freePositions += 1
  elif firstBit != secondBit and firstBit != thirdBit:
    minorityCounts[0] += 1
  elif secondBit != firstBit and secondBit != thirdBit:
    minorityCounts[1] += 1
  else:
    minorityCounts[2] += 1
```

An agreeing coordinate doubles every completion.
A differing coordinate contributes to exactly one count.
The loop runs once per dimension.

**Factorial tables.** Factorials and inverse factorials are built once.

```nim
var factorial = newSeq[int64](dimension + 1)
var inverseFactorial = newSeq[int64](dimension + 1)
factorial[0] = 1
for position in 1 .. dimension:
  factorial[position] = (factorial[position - 1] * int64(position)) mod modulusValue
inverseFactorial[dimension] = powerMod(factorial[dimension], int64(exponentForInverse))
for position in 0 .. dimension - 1:
  inverseFactorial[dimension - 1 - position] =
    (inverseFactorial[dimension - position] * int64(dimension - position)) mod modulusValue
```

Every factorial is reduced modulo 1000000007.
The inverse table is filled from the largest index downward.
Both tables use one array slot per dimension.

**Balance sum.** Each legal balance contributes one product of binomials.

```nim
let smallestCount = min(min(minorityCounts[0], minorityCounts[1]), minorityCounts[2])
var safeTotal: int64 = 0
for balance in -smallestCount .. smallestCount:
  var skipBalance = false
  for houndIndex in 0 .. 2:
    if (balance - minorityCounts[houndIndex]) mod 2 != 0:
      skipBalance = true
  if skipBalance:
    continue
  var ways: int64 = 1
  for houndIndex in 0 .. 2:
    let chosenCount = (minorityCounts[houndIndex] + balance) div 2
    ways = (ways * combination(minorityCounts[houndIndex], chosenCount, factorial, inverseFactorial)) mod modulusValue
  safeTotal = (safeTotal + ways) mod modulusValue
safeTotal = (safeTotal * powerMod(2, int64(freePositions))) mod modulusValue
appendOutput($safeTotal)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The smallest count bounds the balance range.
A parity mismatch skips the balance immediately.
Free positions multiply the total by a power of two.

## Complexity

Each coordinate is classified once and each balance is visited once.

| phase | time | space |
|---|---|---|
| input read | one pass over three strings | one input string |
| pattern counts | one step per coordinate | three count slots |
| balance sum | one step per legal balance | two factorial tables |
| output | one line | block buffer |

The factorial tables and the balance scan dominate both time and space.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) |

Scanning all 2^N cube vertices would be exponential, while this method stays linear.
Counting patterns and summing balances keeps N = 100000 practical.
