# MCIRGAME — Point Connection Game in a Circle (SPOJ)

<https://www.spoj.com/problems/MCIRGAME/>

## Problem

Place the numbers 1 to 2n around a circle and join every number to one partner with straight chords that never cross. Count how many different pairings exist.

Each input line holds one integer n. A line with -1 ends the input. For every other line, print one integer: the number of valid pairings for 2n points.

| Item | Bound |
|---|---|
| Pairs n | 1 to 150 |
| Input lines | until a line with -1 |
| Answer size | up to about 87 decimal digits |
| Judge limit | 1000 ms, 1536 MB |

The answer grows past 64-bit range, so the count needs decimal big-integer storage.

Sample input:

```
2
-1
```

Sample output:

```
2
```

## Idea

Counting pairings works like counting balanced bracket strings: the partner of point 1 splits the remaining points into two smaller independent circles.

The counts are Catalan numbers. Build them with the recurrence C(k+1) = C(k) times (4k+2), divided by (k+2). Store each number as limbs in base 1e9 and multiply or divide by small integers. Precomputing all 150 answers costs a few hundred limb operations per step. Listing every pairing would take exponential time. Compute once, then answer each line by printing a stored string.

## Why It Works

1. Fix the partner of point 1. The chord divides the circle into two arcs.
2. Each arc holds an even number of remaining points, so it forms its own smaller pairing.
3. If one arc holds 2i points, the split contributes C(i) times C(n-1-i) pairings.
4. Summing those products gives the Catalan recurrence used in the code.
5. Every division by (k+2) is exact, so integer limbs keep the result exact.

| Term | Meaning |
|---|---|
| `catalanNumbers` | stored answer for each order from 0 to 150 |
| `numberLimbs` | decimal big integer stored in base 1e9 limbs |
| `bigBase` | value 1e9, the radix of each limb |
| `orderValue` | current Catalan order in the precompute loop |

The recurrence replaces enumeration with a short chain of exact integer steps.

A script trace of the first five orders:

```
order 0 = 1
order 1 -> 1 * 2 / 2 = 1
order 2 -> 1 * 6 / 3 = 2
order 3 -> 2 * 10 / 4 = 5
order 4 -> 5 * 14 / 5 = 14
```

The trace reaches 2 at order 2, which matches the sample answer.

## Code

**Input and scanner.** The program reads all lines and parses signed integers by hand.

```nim
const flushBlockBytes = 1 shl 17
const digitsPerLimb = 9
const bigBase: int64 = 1000000000
const largestQuery = 150

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] != '-' and (data[pos] < '0' or data[pos] > '9')):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value
```

The minus branch handles the -1 terminator.
The loop stops once the scanner reaches the end of input.
Scanning skips all spacing without allocating tokens.

**Big integer operations.** Limbs support exact multiply and divide by small factors.

```nim
proc multiplyByFactor(numberLimbs: var seq[int], factorValue: int64) =
  var carryValue: int64 = 0
  for limbIndex in 0 .. numberLimbs.len - 1:
    let productValue = int64(numberLimbs[limbIndex]) * factorValue + carryValue
    numberLimbs[limbIndex] = int(productValue mod bigBase)
    carryValue = productValue div bigBase
  while carryValue > 0:
    numberLimbs.add(int(carryValue mod bigBase))
    carryValue = carryValue div bigBase

proc divideByFactor(numberLimbs: var seq[int], divisorValue: int64) =
  var remainderValue: int64 = 0
  var limbIndex = numberLimbs.len - 1
  while limbIndex >= 0:
    let currentValue = remainderValue * bigBase + int64(numberLimbs[limbIndex])
    numberLimbs[limbIndex] = int(currentValue div divisorValue)
    remainderValue = currentValue mod divisorValue
    limbIndex -= 1
  while numberLimbs.len > 1 and numberLimbs[numberLimbs.len - 1] == 0:
    numberLimbs.setLen(numberLimbs.len - 1)

proc formatBigNumber(numberLimbs: seq[int]): string =
  result = $numberLimbs[numberLimbs.len - 1]
  var limbIndex = numberLimbs.len - 2
  while limbIndex >= 0:
    let limbText = $numberLimbs[limbIndex]
    var zeroCount = digitsPerLimb - limbText.len
    while zeroCount > 0:
      result.add '0'
      zeroCount -= 1
    result.add limbText
    limbIndex -= 1
```

Products stay under 602 times 1e9, so int64 holds each carry.
Padded limbs print as fixed nine-digit groups.
Leading zero limbs are removed after division.

**Precompute and output.** All answers are built once and written through one buffer.

```nim
var catalanNumbers = newSeq[seq[int]](largestQuery + 1)
var runningNumber = newSeq[int](1)
runningNumber[0] = 1
catalanNumbers[0] = runningNumber
for orderValue in 0 .. largestQuery - 1:
  var nextNumber = newSeq[int]()
  for limbValue in runningNumber:
    nextNumber.add limbValue
  multiplyByFactor(nextNumber, int64(4 * orderValue + 2))
  divideByFactor(nextNumber, int64(orderValue + 2))
  catalanNumbers[orderValue + 1] = nextNumber
  runningNumber = nextNumber

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let queryValue = nextInt(inputData, scanPos)
  if queryValue < 0:
    break
  appendOutput(formatBigNumber(catalanNumbers[queryValue]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs 150 times and stores every Catalan number.
A negative query ends output before any extra line.
Block writes keep output cost proportional to printed digits.

## Complexity

Precompute dominates the work; each query only prints a stored number.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| Precompute | 150 multiply and divide passes | 151 stored big integers |
| Output | one string per query | block buffer |

The table shows that answer printing is cheaper than building the table.

| Measure | Big O |
|---|---|
| Time | O(150 * D + Q * D), D decimal digits |
| Space | O(150 * D) |

Listing every pairing would cost exponential time, while the recurrence stays linear in the digit count.
