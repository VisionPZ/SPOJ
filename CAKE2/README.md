# CAKE2 — Cake (SPOJ)

<https://www.spoj.com/problems/CAKE2/>

## Problem

Draw N distinct infinite lines on a plane and report how many regions they create. Each line is given by two integer points with coordinates up to 10000 in absolute value.

| item | bound |
|---|---|
| lines N | at most 3000 |
| each coordinate | absolute value at most 10000 |
| duplicate lines | none |
| judge limit | 1500 ms, 1536 MB |

A new line adds one region plus one more region for each distinct point where it crosses an earlier line.

Sample input:

```
4
5 0 0 5
4 0 4 5
2 4 3 4
1 1 1 5
```

Sample output:

```
9
```

## Idea

Count crossings as you lay down each line, like slicing a loaf and counting the new faces exposed by each cut. A line's crossings with earlier lines become reduced fractions along that line. Sorting those fractions collapses several lines meeting at one spot into a single point. Each line then adds its own count plus one.

## Why It Works

1. A line with no crossings splits one existing region into two.
2. Each distinct crossing point on a new line splits one more region.
3. Parallel lines share no crossing point and are skipped.
4. Two crossings at the same spot give the same reduced fraction on the line.
5. Summing the distinct counts over all lines gives the total region count.

The names below match the source identifiers.

| term | meaning |
|---|---|
| `lineA`, `lineB`, `lineC` | coefficients of the implicit line equation |
| `denominatorValue` | zero exactly when two lines are parallel |
| `intersectionParameters` | reduced positions of earlier crossings on one line |
| `distinctPoints` | number of unique crossings for the current line |

The reduced fractions make concurrency visible without floating point.

The line-by-line totals for the sample, produced by the oracle in gen.py:

| line | distinct crossings | regions added | running total |
|---|---|---|---|
| 1 | 0 | 1 | 2 |
| 2 | 1 | 2 | 4 |
| 3 | 2 | 3 | 7 |
| 4 | 1 | 2 | 9 |

Lines 1, 3, and 4 meet at one point, counted once for the line added last.

## Code

**Input and exact helpers.** The reader loads the lines and the helpers normalise rational positions.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

type Fraction = tuple[numerator: int64, denominator: int64]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

proc greatestCommonDivisor(firstValue: int64, secondValue: int64): int64 =
  var largerValue = firstValue
  var smallerValue = secondValue
  if largerValue < 0:
    largerValue = -largerValue
  if smallerValue < 0:
    smallerValue = -smallerValue
  while smallerValue != 0:
    let remainderValue = largerValue mod smallerValue
    largerValue = smallerValue
    smallerValue = remainderValue
  return largerValue

proc compareFractions(leftFraction: Fraction, rightFraction: Fraction): int =
  let leftCross = leftFraction.numerator * rightFraction.denominator
  let rightCross = rightFraction.numerator * leftFraction.denominator
  if leftCross < rightCross:
    return -1
  if leftCross > rightCross:
    return 1
  return 0
```

The scanner accepts negative coordinates.
Fractions are reduced with a positive denominator.
Cross multiplication stays inside int64 for the stated bounds.

**Line coefficient setup.** Two points become an implicit equation and a direction.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let lineCount = nextInt(inputData, scanPos)
var lineA = newSeq[int64](lineCount)
var lineB = newSeq[int64](lineCount)
var lineC = newSeq[int64](lineCount)
var lineDirX = newSeq[int64](lineCount)
var lineDirY = newSeq[int64](lineCount)
var lineX1 = newSeq[int64](lineCount)
var lineY1 = newSeq[int64](lineCount)
for lineIndex in 0 ..< lineCount:
  let firstX = int64(nextInt(inputData, scanPos))
  let firstY = int64(nextInt(inputData, scanPos))
  let secondX = int64(nextInt(inputData, scanPos))
  let secondY = int64(nextInt(inputData, scanPos))
  let directionX = secondX - firstX
  let directionY = secondY - firstY
  lineDirX[lineIndex] = directionX
  lineDirY[lineIndex] = directionY
  lineX1[lineIndex] = firstX
  lineY1[lineIndex] = firstY
  lineA[lineIndex] = directionY
  lineB[lineIndex] = -directionX
  lineC[lineIndex] = directionX * firstY - directionY * firstX
```

The equation is directionY times x minus directionX times y plus the constant.
Each pair of coordinates is read as signed integers.
All coefficients fit in int64.

**Region accumulation.** Each line adds one plus its distinct crossing count.

```nim
var regionCount: int64 = 1
for lineIndex in 0 ..< lineCount:
  var intersectionParameters = newSeq[Fraction](lineIndex)
  var parameterCount = 0
  for previousLine in 0 ..< lineIndex:
    let denominatorValue = lineA[previousLine] * lineDirX[lineIndex] + lineB[previousLine] * lineDirY[lineIndex]
    if denominatorValue == 0:
      continue
    var numeratorValue = -(lineA[previousLine] * lineX1[lineIndex] + lineB[previousLine] * lineY1[lineIndex] + lineC[previousLine])
    var positiveDenominator = denominatorValue
    if positiveDenominator < 0:
      positiveDenominator = -positiveDenominator
      numeratorValue = -numeratorValue
    let commonDivisor = greatestCommonDivisor(numeratorValue, positiveDenominator)
    intersectionParameters[parameterCount].numerator = numeratorValue div commonDivisor
    intersectionParameters[parameterCount].denominator = positiveDenominator div commonDivisor
    parameterCount += 1
  intersectionParameters.setLen(parameterCount)
  sort(intersectionParameters, compareFractions)
  var distinctPoints = 0
  var scanIndex = 0
  while scanIndex < parameterCount:
    distinctPoints += 1
    while scanIndex + 1 < parameterCount and intersectionParameters[scanIndex] == intersectionParameters[scanIndex + 1]:
      scanIndex += 1
    scanIndex += 1
  regionCount = regionCount + int64(distinctPoints + 1)

appendOutput($regionCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A zero denominator marks a parallel pair.
Sorting groups equal fractions so one point is counted once.
The single answer is written through the block buffer.

## Complexity

Let N be the number of lines.

| phase | time | space |
|---|---|---|
| coefficient setup | one equation per line | four arrays of N values |
| crossing scan | one fraction per line pair | one list of at most N fractions |
| sorting | sort each line's fractions | the same list |
| output | one append | one block buffer |

Each of the N lines sorts at most N fractions, so the total stays quadratic up to a logarithm.

| measure | Big O |
|---|---|
| time | O(N^2 log N) |
| space | O(N) |

Storing every intersection globally would need O(N^2) memory, while processing one line at a time uses O(N).
