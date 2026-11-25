# FNDMSNG — Find the Missing Number (SPOJ)

<https://www.spoj.com/problems/FNDMSNG/>

## Problem

A list should hold every number from 1 to N, but one value is absent. Find that absent value from the N-1 numbers you are given.

The first line holds N, with 2 ≤ N ≤ 100. The second line holds N-1 distinct integers, each between 1 and N. Print the one integer from 1 to N that does not appear in the second line.

| item | bound |
|---|---|
| N | 2 to 100 |
| given values | N-1 distinct values in 1 to N |
| judge limit | 1000 ms, 1536 MB |

The whole input fits in one short line, so one pass is enough.

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

The missing value is the gap between the sum you expect and the sum you see, like counting the empty chair in a row of numbered seats.

The method uses the arithmetic series sum and one pass over the given values. Each given number costs one addition. A search over every candidate would compare each candidate against the whole list.

Takeaway: one sum replaces a full search.

## Why It Works

1. The numbers 1 through N add up to N times (N + 1), divided by 2.
2. The input lists N-1 distinct values taken from that same set.
3. Their sum equals the full total minus the one absent value.
4. Subtracting the observed sum from the expected sum recovers that value.

| term | meaning |
|---|---|
| `permutationSize` | the largest value N in the range |
| `observedSum` | sum of the N-1 given values |
| `expectedSum` | sum of every value from 1 to N |
| `observedCount` | how many given values were read |

Every term maps to one value in the range.

For the sample, N = 10 gives an expected sum of 10 × 11 / 2 = 55. The given values 10 2 3 1 9 7 8 6 4 add to 50. The difference 55 − 50 = 5 is the answer.

The product uses `int64`, so the sum stays exact even if the bound grows.

## Code

**Input and scanning.** The hand reader loads the size and every given value.

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

Whitespace and line breaks do not affect parsing.
The scanner advances one index per number.
No minus branch is needed because every value is positive.

**Buffered output.** One string collects the answer before a single write.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes only after it grows past the block size.
The final write happens after the computation.

**Sum and answer.** The full total minus the observed total is printed.

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

The loop reads exactly N-1 values.
The division by 2 is exact because one factor is even.
The answer is written once with a trailing newline.

## Complexity

Each given value is read once and added once.

| phase | time | space |
|---|---|---|
| input read | one pass over N-1 values | one input string |
| sum | N-1 additions | constant |
| output | one integer | one block buffer |

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) for the input string |

A candidate-by-candidate search would cost O(N^2) comparisons.

Takeaway: the sum formula solves the task in a single pass.
