# LOOPEXP — Loop Expectation (SPOJ)

<https://www.spoj.com/problems/LOOPEXP/>

## Problem

A loop scans a random permutation of 1 to N and counts how often a new maximum appears. Report the expected count for each given N.

Input starts with the test count T, followed by T lines, each holding one size N. Print one decimal per test, within 1e-6 of the true value.

| item | bound |
|---|---|
| test count T | 1 to 100 |
| array size N | 1 to 100000 |
| allowed error | 1e-6 |
| judge limit | 1000 ms, 1536 MB |

The largest N sets the single precomputation size, and the error bound sets the decimal precision.

Sample input:

```
1
2
```

Sample output:

```
1.5
```

## Idea

The current maximum changes exactly when the largest value seen so far arrives, like noting each new high-water mark. Position i holds the largest of its first i entries with probability 1/i. Summing those probabilities gives the harmonic number H(N), which can be precomputed once for every N up to the largest test.

## Why It Works

1. The if block runs once when position i holds a new record.
2. Every one of the first i values is equally likely to be that record.
3. The probability of a record at i equals 1/i.
4. Linearity of expectation sums the per-position probabilities.
5. The expected count is therefore the harmonic number H(N) = 1 + 1/2 + ... + 1/N.

| term | meaning |
|---|---|
| `harmonicScaled` | running harmonic sum times one billion |
| `runningTotal` | floating-point harmonic sum during precompute |
| `scaleFactor` | ten to the ninth power, the decimal scale |
| `formatScaled` | decimal text with trailing zeros removed |

The two permutations of size two give counts 2 and 1, so the mean is 1.5.

```
N = 2: (2 + 1) / 2 = 1.5
H(2) = 1 + 1/2 = 1.5
scaled = 1500000000 -> 1.5
```

The trace agrees with the sample output.

## Code

**Input and precompute.** All sizes are read first, then one sweep fills the harmonic table.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const scaleFactor = 1000000000

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

The scanner reads positive integers only.
One input string holds every token.
The output buffer collects all answer lines.

**Harmonic table and output.** One pass builds the table, and a trimmer prints short decimals.

```nim
let caseCount = nextInt(inputData, scanPos)
var caseSizes = newSeq[int](caseCount)
var largestSize = 0
var caseIndex = 0
while caseIndex < caseCount:
  caseSizes[caseIndex] = nextInt(inputData, scanPos)
  if caseSizes[caseIndex] > largestSize:
    largestSize = caseSizes[caseIndex]
  caseIndex += 1

var harmonicScaled = newSeq[int64](largestSize + 1)
var runningTotal = 0.0
var sizeIndex = 1
while sizeIndex <= largestSize:
  runningTotal = runningTotal + 1.0 / float64(sizeIndex)
  harmonicScaled[sizeIndex] = int64(runningTotal * float64(scaleFactor) + 0.5)
  sizeIndex += 1

proc formatScaled(scaledValue: int64): string =
  let wholePart = scaledValue div int64(scaleFactor)
  let fractionPart = scaledValue mod int64(scaleFactor)
  if fractionPart == 0:
    return $wholePart
  var fractionText = $fractionPart
  while fractionText.len < 9:
    fractionText = "0" & fractionText
  while fractionText[fractionText.len - 1] == '0':
    fractionText.setLen(fractionText.len - 1)
  return $wholePart & "." & fractionText

caseIndex = 0
while caseIndex < caseCount:
  appendOutput(formatScaled(harmonicScaled[caseSizes[caseIndex]]))
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

The table is built once up to the largest requested size.
Nine fractional digits keep rounding below the allowed error.
Trailing zeros are removed so the sample prints as 1.5.

## Complexity

The precompute dominates and runs once per input file.

| phase | time | space |
|---|---|---|
| input read | one pass over T sizes | one input string |
| harmonic table | one pass up to the largest N | N int64 cells |
| output | one trimmed line per test | block buffer |

Each test after precompute costs one table lookup.

| measure | Big O |
|---|---|
| time | O(T + max N) |
| space | O(max N) |

Summing records for each permutation separately would need factorial time, while the harmonic sum costs one precompute.
