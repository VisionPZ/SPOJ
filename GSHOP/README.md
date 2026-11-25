# GSHOP — Rama and Friends (SPOJ)

<https://www.spoj.com/problems/GSHOP/>

## Problem

Given a sorted integer array, flip signs exactly k times to make the final sum as large as possible. A flip changes x into -x and may hit the same element repeatedly.

Input starts with the case count T. Each case gives n and k on one line, then n non-decreasing integers on the next line.

Output one maximum sum per case.

| item | bound |
|---|---|
| cases T | 1 to 10 |
| elements n | 1 to 100 |
| flips k | 1 to 100 |
| array values | -100000 to 100000 |
| judge limit | 106 ms, 1536 MB |

The small n and k bounds keep an exact scan cheap.

Sample input:

```
1
3 1
-1 -1 1
```

Sample output:

```
1
```

## Idea

Spend flips on the most negative values first, like paying the largest debts first to lift a balance fastest.

A flip of a negative value adds twice its magnitude to the total. Since the array is sorted, those values come first. Each flip after the negatives needs a parity guard: two flips on one element cancel, and a zero absorbs any flip for free. The scan runs once per element and keeps four running counts. A dynamic program over flip counts would explore many more states.

Greedy selection with a parity guard solves each case in one pass.

## Why It Works

1. Flipping a negative value x changes the sum by -2 times x, a positive gain.
2. The array order already ranks those gains from largest to smallest.
3. Spending a flip twice on one element returns it to its starting sign.
4. When flips remain after all negatives, only the parity of the remainder matters.
5. A zero absorbs one flip at zero cost, so an odd remainder is free there.
6. Without a zero, an odd remainder costs twice the smallest absolute value.

| term | meaning |
|---|---|
| `totalSum` | sum of the array before any flip |
| `gain` | magnitudes of the negative values flipped once |
| `negativeCount` | number of negative values seen |
| `zeroCount` | number of zeros seen |
| `smallestAbsolute` | smallest nonzero magnitude in the array |
| `leftover` | flips left after flipping the negatives |
| `penalty` | cost of an odd remainder when no zero exists |
| `bestSum` | maximum final sum for the case |

The table names every value the scan carries from input to answer.

A script-traced run on the sample shows the arithmetic:

```
values: [-1, -1, 1]  total: -1  flips: 1
first negative flipped: gain 1, running sum 1
final answer: 1
```

The single flip turns the first -1 into 1, giving the sample answer.

The guard on `leftover` handles the parity case. The guard on `zeroCount` handles free flips.

## Code

**Input and scanner.** The reader loads all tokens and parses signed integers.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const doubled = 2

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner accepts a leading minus sign for negative array values.
The output buffer flushes in large blocks, not once per case.
The scan costs one pass over the input characters.

**Greedy scan.** One pass computes gains, counts, and the parity penalty.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  let operationCount = nextInt(inputData, scanPos)
  var totalSum: int64 = 0
  var gain: int64 = 0
  var negativeCount = 0
  var zeroCount = 0
  var smallestAbsolute: int64 = 0
  for elementIndex in 0 .. elementCount - 1:
    let elementValue = int64(nextInt(inputData, scanPos))
    totalSum = totalSum + elementValue
    if elementValue < 0:
      if negativeCount < operationCount:
        gain = gain - elementValue
      negativeCount += 1
    elif elementValue == 0:
      zeroCount += 1
    if elementValue != 0:
      let absoluteValue = if elementValue < 0: -elementValue else: elementValue
      if smallestAbsolute == 0 or absoluteValue < smallestAbsolute:
        smallestAbsolute = absoluteValue
  var flippedNegatives = negativeCount
  if flippedNegatives > operationCount:
    flippedNegatives = operationCount
  let leftover = operationCount - flippedNegatives
  var penalty: int64 = 0
  if zeroCount == 0 and leftover mod 2 == 1:
    penalty = doubled * smallestAbsolute
  let bestSum = totalSum + doubled * gain - penalty
  appendOutput($bestSum)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The `gain` line caps flips at `operationCount` without a second scan.
The loop bound is the element count from the case header.
The penalty applies only when an odd flip remains and no zero exists.

## Complexity

Each case reads its array once and writes one answer line.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| greedy scan | one pass over n elements | four running counters |
| output | one line per case | block buffer |

The input pass and the greedy scan both scale with the token count.

| measure | Big O |
|---|---|
| time | O(total n + total k) |
| space | O(1) beyond input and output buffers |

A dynamic program over flip counts costs O(n times k squared), far more work per element.
The greedy scan with its parity guard is the whole solution.
