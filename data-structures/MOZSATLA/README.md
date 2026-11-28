# MOZSATLA — Sharmeen and the Lost Array (SPOJ)

<https://www.spoj.com/problems/MOZSATLA/>

## Problem

Restore an array from comparison signs between neighbors, using positive integers and choosing the lexicographically smallest array. A sign says equal, strictly increasing, or strictly decreasing.

Input starts with test count t. Each case gives n, then the n-1 comparison codes: 0 for equal, 1 for less, 2 for greater. Output one line per case with the n restored values.

| item | bound |
|---|---|
| test cases t | 1 to 100 |
| array size n | 1 to 100000 |
| comparison code | 0, 1, or 2 |
| judge limit | 1000 ms, 1536 MB |

Neighboring codes push values from both sides, so both directions matter.

Sample input:

```
1
5
1 2 0 1
```

The statement prints these three lines on one line as `151 2 0 1`; the tokens are t = 1, n = 5, then codes 1, 2, 0, 1.

Sample output:

```
1 2 1 1 2
```

## Idea

Think of two crowds pushing a row of posts from each end. A rising code pushes the right post higher; a falling code pushes the left post higher. Every post ends at the taller of the two pushes, plus one. That is a two-sided lower-bound sweep, costing one pass from each end. Searching all arrays with backtracking repeats work and does not scale.

Compute left bounds forward and right bounds backward. Write the larger bound plus one for each position.

## Why It Works

1. A code of 1 gives a lower bound on the right neighbor from the left neighbor.
2. A code of 2 gives a lower bound on the left neighbor from the right neighbor.
3. A code of 0 carries the same lower bound across the pair.
4. A falling code resets the forward bound, and a rising code resets the backward bound.
5. Each value must clear both bounds, so the smallest choice is their maximum plus one.

| term | meaning |
|---|---|
| `relations` | comparison codes between neighbors |
| `forwardLevels` | lower bound from the left, measured above 1 |
| `backwardLevels` | lower bound from the right, measured above 1 |
| `neededLevel` | larger of the two bounds at one position |

For the sample codes 1, 2, 0, 1, the forward bounds are 0, 1, 0, 0, 1. The backward bounds are 0, 1, 0, 0, 0.

| position | code | forward | backward | value |
|---|---|---|---|---|
| 1 | - | 0 | 0 | 1 |
| 2 | 1 | 1 | 1 | 2 |
| 3 | 2 | 0 | 0 | 1 |
| 4 | 0 | 0 | 0 | 1 |
| 5 | 1 | 1 | 0 | 2 |

The last column matches the sample output.

## Code

**Input and scanning.** The reader loads stdin and stores each case's codes.

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

The scanner skips whitespace, so packed sample lines parse correctly. Codes stay in one sequence per case.

**Two-sided bounds and output.** One sweep per side fixes every value.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let arraySize = nextInt(inputData, scanPos)
  var relations = newSeq[int](arraySize - 1)
  for relationIndex in 0 .. arraySize - 2:
    relations[relationIndex] = nextInt(inputData, scanPos)
  var forwardLevels = newSeq[int](arraySize)
  var backwardLevels = newSeq[int](arraySize)
  forwardLevels[0] = 0
  for relationIndex in 0 .. arraySize - 2:
    forwardLevels[relationIndex + 1] = 0
    if relations[relationIndex] == 0:
      forwardLevels[relationIndex + 1] = forwardLevels[relationIndex]
    elif relations[relationIndex] == 1:
      forwardLevels[relationIndex + 1] = forwardLevels[relationIndex] + 1
  backwardLevels[arraySize - 1] = 0
  var reverseIndex = arraySize - 2
  while reverseIndex >= 0:
    backwardLevels[reverseIndex] = 0
    if relations[reverseIndex] == 0:
      backwardLevels[reverseIndex] = backwardLevels[reverseIndex + 1]
    elif relations[reverseIndex] == 2:
      backwardLevels[reverseIndex] = backwardLevels[reverseIndex + 1] + 1
    reverseIndex -= 1
  let leadingLevel = if forwardLevels[0] > backwardLevels[0]: forwardLevels[0] else: backwardLevels[0]
  appendOutput($(leadingLevel + 1))
  for position in 1 .. arraySize - 1:
    let neededLevel = if forwardLevels[position] > backwardLevels[position]: forwardLevels[position] else: backwardLevels[position]
    appendOutput(" ")
    appendOutput($(neededLevel + 1))
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

A falling code resets the forward bound, and a rising code resets the backward bound. The larger bound plus one is the smallest valid value. Large outputs flush in blocks.

## Complexity

Each case sweeps its codes twice.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| two-sided bounds | two passes over n-1 codes | two bound sequences |
| output | buffered values per case | block buffer |

The two sweeps keep the cost linear in the array size.

| measure | Big O |
|---|---|
| time | O(n) per case |
| space | O(n) per case |

Trying candidate arrays by backtracking takes exponential time in the worst case, while the two-sided sweep fixes every value in linear time. That sweep sets the cost.
