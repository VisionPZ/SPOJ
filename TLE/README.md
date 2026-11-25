# TLE — Time Limit Exceeded (SPOJ)

<https://www.spoj.com/problems/TLE/>

## Problem

Count value sequences where each entry dodges one divisor and neighbors share no set bit. Report the count modulo one billion.

Input starts with the test count T. Each case gives N, M, then N divisors c_i. Entry a_i lies from 0 to 2^M - 1, and a_i is not divisible by c_i.

Neighboring entries satisfy a zero bitwise AND. Output one count per case.

| item | bound |
|---|---|
| test cases T | 1 to 10 |
| sequence length N | 1 to 50 |
| bits M | 1 to 15 |
| divisor c_i | 1 to 2M |
| judge limit | 1000 ms, 1536 MB |

The bit width drives the state count, since 2^15 equals 32768 values.

Sample input:

```
1
2 2
3 2
```

Sample output:

```
1
```

## Idea

Treat each value as a switch pattern, and each neighbor must press none of the switches you pressed. A subset total adds every compatible predecessor at once, like summing one whole spreadsheet column with a single formula. The method is dynamic programming plus a zeta transform over bitmasks.

Each position costs O(M * 2^M) additions.

Testing every predecessor pair costs O(4^M) work and loses the speed. One subset total per mask keeps each step small.

## Why It Works

1. Values occupy 2^M states indexed by their bit patterns.
2. Values u and v have a zero AND when u fits inside the complement of v.
3. The complement mask is `fullMask xor value`, and its subsets are all legal predecessors.
4. A zeta transform replaces a mask with the sum over its subsets in O(M * 2^M) steps.
5. The divisor rule keeps only values that are not divisible by c_i.
6. Summing the final row yields the count for every valid sequence.

The main arrays:

| term | meaning |
|---|---|
| `stateCount` | number of values, 2 raised to M |
| `fullMask` | mask with all M bits set |
| `complementOf` | complement of each value inside `fullMask` |
| `subsetTotals` | sum of predecessor ways over subsets of each mask |
| `waysEnding` | ways for each value at the current position |

Each array holds one count per state.

A trace of the sample, with N = 2 and M = 2:

```
states       0 1 2 3
c1 = 3        0 1 1 1
subset sums   0 1 1 2
c2 = 2        0 1 0 0
ways at 1     subset sums[2] = 1
ways at 3     subset sums[0] = 0
answer        1
```

The trace matches the sample answer of one sequence, namely 2 then 1.

Subset sums stay below 3.3e13, so 64-bit integers hold them before one modulo.

## Code

**Input and divisor tables.** The reader loads cases and caches value flags.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000000

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
```

The scanner skips all spacing. One cached table serves each divisor. The buffer flushes in large blocks.

**Subset sweep and output.** The transform feeds the next row of counts.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sequenceLength = nextInt(inputData, scanPos)
  let bitCount = nextInt(inputData, scanPos)
  var forbiddenDivisors = newSeq[int](sequenceLength)
  for position in 0 .. sequenceLength - 1:
    forbiddenDivisors[position] = nextInt(inputData, scanPos)
  let stateCount = 1 shl bitCount
  let fullMask = stateCount - 1
  var complementOf = newSeq[int](stateCount)
  for value in 0 .. stateCount - 1:
    complementOf[value] = fullMask xor value
  var allowedByDivisor = newSeq[seq[bool]](2 * bitCount + 1)
  for divisor in 1 .. 2 * bitCount:
    var allowedHere = newSeq[bool](stateCount)
    for value in 0 .. stateCount - 1:
      allowedHere[value] = value mod divisor != 0
    allowedByDivisor[divisor] = allowedHere
  var waysEnding = newSeq[int64](stateCount)
  var nextWays = newSeq[int64](stateCount)
  var subsetTotals = newSeq[int64](stateCount)
  let firstAllowed = allowedByDivisor[forbiddenDivisors[0]]
  for value in 0 .. stateCount - 1:
    if firstAllowed[value]:
      waysEnding[value] = 1
  if sequenceLength > 1:
    for position in 1 .. sequenceLength - 1:
      for value in 0 .. stateCount - 1:
        subsetTotals[value] = waysEnding[value]
      for bitIndex in 0 .. bitCount - 1:
        let bitValue = 1 shl bitIndex
        for value in 0 .. stateCount - 1:
          if (value and bitValue) != 0:
            subsetTotals[value] = subsetTotals[value] + subsetTotals[value - bitValue]
      let allowedHere = allowedByDivisor[forbiddenDivisors[position]]
      for value in 0 .. stateCount - 1:
        if allowedHere[value]:
          nextWays[value] = subsetTotals[complementOf[value]] mod int64(modulusValue)
        else:
          nextWays[value] = 0
      swap waysEnding, nextWays
  var totalWays: int64 = 0
  for value in 0 .. stateCount - 1:
    totalWays = (totalWays + waysEnding[value]) mod int64(modulusValue)
  appendOutput($totalWays)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The inner loop runs M times over all states. Divisibility filters each next row. One line is written per case.

## Complexity

Every case performs M subset sweeps per position.

| phase | time | space |
|---|---|---|
| input read | one pass over case tokens | input string |
| divisor tables | 2M tables of 2^M flags | cached flags |
| subset sweep | N times M times 2^M additions | three state arrays |
| output | one line per case | block buffer |

The cached divisor flags serve every position in a case.

| measure | Big O |
|---|---|
| time | O(T * N * M * 2^M) |
| space | O(M * 2^M) |

Pair checking would cost O(T * N * 4^M), far above this bound. Subset totals make the sweep scale with M instead of with 2^M squared.
