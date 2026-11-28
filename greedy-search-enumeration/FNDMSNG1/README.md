# FNDMSNG1 — Find the missing number (SPOJ)

<https://www.spoj.com/problems/FNDMSNG1/>

## Problem

The numbers 1 through N are written down, but one of them is skipped. Given the remaining N-1 numbers, name the missing one.

The first line holds N with 2 ≤ N ≤ 100. The second line holds N-1 distinct values from 1 to N in any order. The output is the single missing number.

| item | bound |
|---|---|
| N | 2 ≤ N ≤ 100 |
| given values | N-1 distinct values from 1..N |
| judge limit | 1000 ms, 1536 MB |

One subtraction chain recovers the missing value.

Sample input:

```
10
10 2 3 1 9 7 8 6 4
```

Sample output:

```
5
```

## Idea

A full deck has a known total. Pull one card and the missing rank is the gap between the full total and what remains.

The program starts with the sum 1 + 2 + ... + N, computed by the closed formula, then subtracts every given number. What is left is the missing number.

Takeaway: the total minus the seen sum is the unseen value.

## Why It Works

1. The formula N(N+1)/2 equals the sum of 1 through N.
2. The input lists exactly the other N-1 numbers, each once.
3. Subtracting them all removes every present value from the total.
4. The only untouched term is the missing number.

For the sample, the full sum is 55 and the given values add to 50, so 5 is missing.

N is at most 100, so the running total stays small and fits in one machine word.

## Code

**Input and scanning.** The hand reader loads the file and parses integers.

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
```

The scanner skips spaces and newlines.
Every value is positive, so no minus branch is needed.

**Buffered output.** One string collects the answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Total and subtraction.** The formula sets the target, the loop removes the seen values.

```nim
let permutationSize = nextInt(inputData, scanPos)
var observedSum: int64 = 0
var observedCount = 0
while observedCount < permutationSize - 1:
  observedSum = observedSum + int64(nextInt(inputData, scanPos))
  observedCount += 1
let expectedSum = int64(permutationSize) * int64(permutationSize + 1) div 2
appendOutput($(expectedSum - observedSum))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly N-1 times.
The leftover total is written as the answer.

## Complexity

The program reads N numbers and does one subtraction each.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| scan | N-1 subtractions | none |
| output | one line | none |

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(1) |

A visited-flag array would also work but needs extra memory.

Takeaway: sums find missing items without storage.
