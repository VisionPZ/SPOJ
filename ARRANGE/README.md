# ARRANGE — Arranging Amplifiers (SPOJ)

<https://www.spoj.com/problems/ARRANGE/>

## Problem

Choose an order for the amplifiers so the final signal is strongest. An amplifier with factor Y turns an incoming signal X into Y raised to X. The first amplifier receives signal 1.

Input begins with T, the number of test cases. Each case gives n, then n positive factors on the next line. Print one line per case: the chosen factors in order, separated by spaces. Among equally strong orders, print the one with bigger factors first.

| item | bound |
|---|---|
| test cases T | 1 to 20 |
| amplifiers n | 1 to 100000 |
| factor value | 1 to 1000000000 |
| distinct values | factors above 1 are unique |
| judge limit | 1000 ms, 1536 MB |

One signal of 1 resets everything, so every factor equal to 1 belongs at the front.

Sample input:

```
2
3
5 6 4
2
2 3
```

Sample output:

```
6 5 4
2 3
```

## Idea

The best order is almost sorted descending, like stacking the heaviest boxes lowest. A descending order wins because each later factor raises an already large exponent. The one exception is a leading pair 3 then 2, where the incoming signal is still 1. Swap those two to 2 then 3. The method is sorting plus one local fix: each case costs O(n log n). A full search over all orders would cost factorial time. Takeaway: sort first, then correct the single weak spot.

## Why It Works

1. With factors a then b and incoming signal X, the outgoing signal is b raised to a raised to X.
2. Compare two adjacent factors with logarithms: b to the a-to-the-X beats a to the b-to-the-X when X is large and a exceeds b.
3. For X of at least 2, descending order wins for every pair of factors above 1.
4. At the first factor above 1, X equals 1, and only the pair 3 then 2 prefers the reverse order.
5. A factor 1 returns signal 1, so placing all ones first never shrinks the final signal.

| term | meaning |
|---|---|
| `onesSeen` | count of factors equal to 1 |
| `largeFactors` | factors above 1, sorted descending |
| `carriedFactor` | factor moved left during insertion sort |
| `printedAny` | whether the current line already has a number |

The table names the values that drive the ordering rule.

The sample factors 5, 6, 4 sort to 6, 5, 4. The leading pair is 6 then 5, so no swap applies. The second case sorts to 3 then 2, so it becomes 2 then 3.

Both sample lines follow from the single swap rule.

## Code

**Input and scanning.** The hand reader loads all cases into one buffer.

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

The scanner skips whitespace and line breaks.
It builds each value one digit at a time.
The buffer flushes in large blocks, not per number.

**Sorting and swap.** Insertion sort orders the factors above 1.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc sortFactors(values: var seq[int], lowIndex: int, highIndex: int) =
  if lowIndex >= highIndex:
    return
  let pivotValue = values[(lowIndex + highIndex) div 2]
  var leftIndex = lowIndex
  var rightIndex = highIndex
  while leftIndex <= rightIndex:
    while values[leftIndex] > pivotValue:
      leftIndex += 1
    while values[rightIndex] < pivotValue:
      rightIndex -= 1
    if leftIndex <= rightIndex:
      swap values[leftIndex], values[rightIndex]
      leftIndex += 1
      rightIndex -= 1
  sortFactors(values, lowIndex, rightIndex)
  sortFactors(values, leftIndex, highIndex)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let amplifierCount = nextInt(inputData, scanPos)
  var onesSeen = 0
  var largeFactors = newSeq[int](0)
  for amplifierIndex in 0 .. amplifierCount - 1:
    let factor = nextInt(inputData, scanPos)
    if factor == 1:
      onesSeen += 1
    else:
      largeFactors.add factor
  sortFactors(largeFactors, 0, largeFactors.len - 1)
  if largeFactors.len >= 2 and largeFactors[0] == 3 and largeFactors[1] == 2:
    largeFactors[0] = 2
    largeFactors[1] = 3
```

Ones are counted separately and never enter the sort.
Quicksort handles up to 100000 factors per case.
The swap checks only the first two sorted factors.

**Output.** The chosen order is written as one line per case.

```nim
  var printedAny = false
  for oneIndex in 0 .. onesSeen - 1:
    if printedAny:
      outputBuffer.add ' '
    appendOutput("1")
    printedAny = true
  for factorIndex in 0 .. largeFactors.len - 1:
    if printedAny:
      outputBuffer.add ' '
    appendOutput($largeFactors[factorIndex])
    printedAny = true
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A single space separates adjacent factors.
The final newline ends each case.
One flush writes the remaining buffer.

## Complexity

Sorting dominates the work in each case.

| phase | time | space |
|---|---|---|
| input read | one pass over the input bytes | one input string |
| sorting | quicksort over n factors | array of n integers |
| output | one pass over n factors | block buffer |

Each case holds one array of factors and one output buffer.

| measure | Big O |
|---|---|
| time per case | O(n log n) average with quicksort |
| space per case | O(n) |

A full permutation search would cost O(n!) time per case. The sort-based rule finishes with a short pass over the output.
