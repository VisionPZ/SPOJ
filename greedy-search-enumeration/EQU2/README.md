# EQU2 — Yet Another Equation (SPOJ)

<https://www.spoj.com/problems/EQU2/>

## Problem

For each given integer n, find the smallest positive integers x and y that satisfy x squared minus n times y squared equals one. Print x and y separated by a space on their own line.

The first line gives the number of test cases. Each following line gives one n between 2 and 1000. A solution exists for every given n.

| item | bound |
|---|---|
| test cases | about 30 |
| coefficient n | 2 to 1000 |
| unknowns | strictly positive integers |
| judge limit | 4739 ms |

The smallest solution is the first convergent of the square root of n that solves the equation.

Sample input:

```
3
2
6
61
```

Sample output:

```
3 2
5 2
1766319049 226153980
```

## Idea

Expand the square root of n as a repeating continued fraction, like unfolding a strip of paper that curls back on itself.

The algorithm finds the repeat length, then builds convergents up to index length minus one for an even period or twice the length minus one for an odd period. Each convergent costs constant work and uses only integer arithmetic. Brute force over y would scan billions of values before reaching the answer for n equals 61.

The repeat length tells exactly which convergent to print.

## Why It Works

1. The continued fraction of the square root of a nonsquare integer repeats after a finite block.
2. Updating m, d, and a with the standard recurrence generates one term of that block per step.
3. The block ends when a equals twice the integer square root.
4. Convergents are built from p and q with p next equals a times p plus the previous p, and likewise for q.
5. The fundamental solution appears at index period minus one for an even period, and at index twice period minus one for an odd period.

| term | meaning |
|---|---|
| `wholePart` | integer square root of n, the first fraction term |
| `periodLength` | number of terms in the repeating block |
| `targetIndex` | convergent index that holds the answer |
| `currentNumerator` | current x value in the convergent sequence |
| `currentDenominator` | current y value in the convergent sequence |

The table shows that the algorithm needs only five integers.

A trace for three sample coefficients:

```
n   wholePart  periodLength  targetIndex  x           y
2   1           1             1            3           2
6   2           2             1            5           2
61  7           11            21           1766319049  226153980
```

The trace reproduces every line of the sample output.

## Code

**Input and buffering.** The program reads all lines once and buffers results.

```nim
const flushBlockBytes = 1 shl 17

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

The scanner ignores line breaks and spaces.
One string holds the complete output.
Flushing uses fixed size blocks, then one final write.

**Continued fraction solver.** The solver finds the period and the target convergent.

```nim
proc integerSquareRoot(value: int): int =
  var root = 0
  while (root + 1) * (root + 1) <= value:
    root += 1
  return root

proc pellSolution(value: int): tuple[xValue: int, yValue: int] =
  let wholePart = integerSquareRoot(value)
  var term = wholePart
  var numerator = 0
  var denominator = 1
  var periodLength = 0
  while true:
    numerator = denominator * term - numerator
    denominator = (value - numerator * numerator) div denominator
    term = (wholePart + numerator) div denominator
    periodLength += 1
    if term == 2 * wholePart:
      break
  var targetIndex = periodLength - 1
  if periodLength mod 2 == 1:
    targetIndex = 2 * periodLength - 1
  var previousNumerator = 1
  var currentNumerator = wholePart
  var previousDenominator = 0
  var currentDenominator = 1
  var convergentIndex = 1
  term = wholePart
  numerator = 0
  denominator = 1
  while convergentIndex <= targetIndex:
    numerator = denominator * term - numerator
    denominator = (value - numerator * numerator) div denominator
    term = (wholePart + numerator) div denominator
    let nextNumerator = term * currentNumerator + previousNumerator
    let nextDenominator = term * currentDenominator + previousDenominator
    previousNumerator = currentNumerator
    currentNumerator = nextNumerator
    previousDenominator = currentDenominator
    currentDenominator = nextDenominator
    convergentIndex += 1
  return (currentNumerator, currentDenominator)
```

The first loop stops at the end of the repeating block.
An odd period needs a second pass through the block.
The second loop builds only the convergents up to the target index.

**Case loop.** Each coefficient produces one answer line.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let coefficient = nextInt(inputData, scanPos)
  let solution = pellSolution(coefficient)
  appendOutput($solution.xValue & " " & $solution.yValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Every case calls the solver once.
The answer is written as two decimal integers.
The final flush ends the output stream.

## Complexity

The work per case is proportional to the convergent index.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| fraction solver | one pass for the period and one for convergents | constant integers |
| output | one line per case | block buffer |

The phase table shows that long periods cost more than short ones.

| measure | Big O |
|---|---|
| time | O(period length) per case |
| space | O(1) per case |

Scanning y values would take exponential time in the size of the answer, while convergents take only linear time in the period.
