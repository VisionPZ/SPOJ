# DCEPCA06 — Saving BOB (SPOJ)
<https://www.spoj.com/problems/DCEPCA06/>

## Problem

Count N-digit integers whose neighboring digits differ by at least K, and print the count modulo one billion and seven. Each test case supplies the length and the minimum gap.

Input starts with the test count, followed by one length and gap per line. Output one line per case with the reduced count.

| item | bound |
|---|---|
| test cases T | 100 |
| length N | 2 to 1000000000 |
| gap K | 0 to 9 |
| judge limit | 1000 ms, 1536 MB |

The leading digit cannot be zero, and later digits may be zero.

Sample input:

```
2
2 9
2 8
```

Sample output:

```
1
4
```

## Idea

Treat each allowed digit jump as an edge and count walks of length N minus one, like counting routes through a ten-station network. Squaring the ten by ten edge matrix repeatedly jumps many steps at once, so a billion digits need about thirty rounds. Precompute the powers for every gap once, then apply only the needed powers to a starting vector. Walking digit by digit would take N rounds; squaring takes logarithmic rounds.

Each query costs ten by ten matrix-vector products per set bit.

## Why It Works

1. A valid integer corresponds to a walk whose first vertex is a nonzero digit.
2. The transition matrix has a one wherever two digits differ by at least K.
3. Multiplying the starting vector by the transition extends every walk by one digit.
4. Repeated squaring builds the transition for two, four, eight, and more steps.
5. Summing the final vector counts all endings, then the modulo keeps values small.

| term | meaning |
|---|---|
| `transitionPowers` | squared transition matrices for each gap |
| `state` | counts of partial numbers ending at each digit |
| `gapValue` | required minimum difference between neighbors |
| `absoluteDifference` | absolute value of the digit difference |

The worked example uses length two and gap eight.

| leading digit | allowed second digits | count |
|---|---|---|
| 8 | 0 | 1 |
| 9 | 0, 1 | 2 |
| 1 | 9 | 1 |

The four numbers are 80, 90, 91, and 19.

All products use int64, and the modulo is applied after every addition.

## Code

**Input and scanner.** The reader loads all lines and parses each pair of integers.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007
const digitCount = 10
const maximumBit = 30

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

```

**Output helper.** Buffered writes avoid one system call per case.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

```

**Helpers.** The digit distance and matrix product use modular arithmetic.

```nim
proc absoluteDifference(firstDigit, secondDigit: int): int =
  if firstDigit >= secondDigit:
    return firstDigit - secondDigit
  return secondDigit - firstDigit

proc multiplyMatrices(leftMatrix: seq[seq[int64]], rightMatrix: seq[seq[int64]]): seq[seq[int64]] =
  result = newSeq[seq[int64]](digitCount)
  for rowIndex in 0 .. digitCount - 1:
    result[rowIndex] = newSeq[int64](digitCount)
    for columnIndex in 0 .. digitCount - 1:
      var total: int64 = 0
      for innerIndex in 0 .. digitCount - 1:
        total = (total + leftMatrix[rowIndex][innerIndex] * rightMatrix[innerIndex][columnIndex]) mod modulusValue
      result[rowIndex][columnIndex] = total

```

The product reduces after each inner term, so no intermediate value overflows.
The distance helper avoids a negative difference for any digit order.

**Power table.** Each gap gets its own chain of squared transitions.

```nim
var transitionPowers = newSeq[seq[seq[seq[int64]]]](digitCount)
for gapValue in 0 .. digitCount - 1:
  var baseMatrix = newSeq[seq[int64]](digitCount)
  for previousDigit in 0 .. digitCount - 1:
    baseMatrix[previousDigit] = newSeq[int64](digitCount)
    for nextDigit in 0 .. digitCount - 1:
      if absoluteDifference(previousDigit, nextDigit) >= gapValue:
        baseMatrix[previousDigit][nextDigit] = 1
  transitionPowers[gapValue] = newSeq[seq[seq[int64]]](maximumBit)
  transitionPowers[gapValue][0] = baseMatrix
  for bitIndex in 1 .. maximumBit - 1:
    transitionPowers[gapValue][bitIndex] = multiplyMatrices(
      transitionPowers[gapValue][bitIndex - 1], transitionPowers[gapValue][bitIndex - 1])

```

Thirty levels cover lengths up to one billion steps.

**Query loop.** The binary decomposition of N minus one selects the powers to apply.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberLength = nextInt(inputData, scanPos)
  let gapValue = nextInt(inputData, scanPos)
  var state = newSeq[int64](digitCount)
  for leadingDigit in 1 .. digitCount - 1:
    state[leadingDigit] = 1
  var remainingSteps = numberLength - 1
  var bitIndex = 0
  while remainingSteps > 0:
    if (remainingSteps and 1) == 1:
      var updated = newSeq[int64](digitCount)
      for previousDigit in 0 .. digitCount - 1:
        for nextDigit in 0 .. digitCount - 1:
          updated[nextDigit] = (updated[nextDigit] + state[previousDigit] *
            transitionPowers[gapValue][bitIndex][previousDigit][nextDigit]) mod modulusValue
      state = updated
    remainingSteps = remainingSteps shr 1
    bitIndex += 1
  var answer: int64 = 0
  for lastDigit in 0 .. digitCount - 1:
    answer = (answer + state[lastDigit]) mod modulusValue
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The starting vector places one walk at each nonzero leading digit.
A set bit updates the vector with the matching precomputed matrix.
The final sum is printed after the modulo reduction.

## Complexity

Powers are built once before any test case is read.

| phase | time | space |
|---|---|---|
| power table | 10 gaps times 30 squarings | 300 matrices of 100 entries |
| one query | at most 30 vector products | one vector of 10 counts |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| preprocessing | O(10 log N times 1000) |
| per test | O(log N times 100) |
| space | O(10 log N times 100) |

Walking one digit at a time would need N steps per test case.

Squaring reduces that to a few dozen steps even at the largest length.
