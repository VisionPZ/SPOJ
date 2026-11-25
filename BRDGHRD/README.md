# BRDGHRD — Building Bridges(HARD) (SPOJ)

<https://www.spoj.com/problems/BRDGHRD/>

## Problem

Each side of a canyon holds identified points in a fixed order. A bridge may join only the i-th point on one side to the i-th point on the other. Pick the largest group of bridges whose segments never cross.

Input starts with the number of test cases. Each case gives n, then n x-coordinates on the first side, then n x-coordinates on the second side. Print one line per case with the largest possible number of bridges.

| item | bound |
|---|---|
| test cases | not stated |
| points per case n | 1 to 100000 |
| x-coordinate | -1000000 to 1000000 |
| judge limit | 1000 ms, 1536 MB |

The size bound rules out comparing every pair of bridges.

Sample input:

```
3
4
2 5 8 10
6 4 1 2
3
5 3 10
6 4 1
6
1 2 3 4 5 6
3 4 5 6 1 2
```

Sample output:

```
2
2
4
```

The third case keeps four bridges in their original order.

## Idea

Think of each bridge as a pin with two coordinates, and the chosen pins must let a rubber band pass without folding back. Two bridges cross exactly when their two endpoint orders disagree. Sort the pairs by first coordinate, then take the longest non-decreasing run of second coordinates. Patience sorting finds that run in O(n log n) per case, while checking every pair of bridges costs O(n^2). The length of the run is the answer.

## Why It Works

1. Two bridges i and j do not cross when the sign of their first-coordinate difference matches the sign of their second-coordinate difference.
2. Equal coordinates on either side never create a crossing, so equal second coordinates belong in the same run.
3. Sorting by first coordinate, then by second coordinate, puts every valid group in order.
4. A non-decreasing run of second coordinates in that order is exactly one valid group.
5. The longest such run is therefore the maximum number of bridges.

| term | meaning |
|---|---|
| endpointPairs | one bridge, stored with both coordinates |
| tailValues | smallest possible tail of a run of each length |
| upperPosition | first index with a value greater than the target |
| comparePairs | orders pairs by first, then second coordinate |

The table names the four pieces that turn geometry into a sequence problem.

The generator traces the first sample case as follows:

```
6 -> [6]
4 -> [4]
1 -> [1]
2 -> [1, 2]
```

The final tail list has two entries, matching the first answer of 2.

Negative coordinates need the minus branch of the scanner. Equal second coordinates use an upper bound, not a lower bound, so ties extend a run.

## Code

**Input and helpers.** The reader accepts negative coordinates and the comparator orders whole pairs.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value
```

The scanner skips separators and keeps a leading minus sign.
Coordinates stay within 32-bit range, so plain integers hold them.
All cases are parsed from one buffered input string.

**Ordering and patience sorting.** Each case sorts its pairs, then grows the run tails.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc comparePairs(left: tuple[firstValue: int, secondValue: int], right: tuple[firstValue: int, secondValue: int]): int =
  if left.firstValue < right.firstValue:
    return -1
  if left.firstValue > right.firstValue:
    return 1
  if left.secondValue < right.secondValue:
    return -1
  if left.secondValue > right.secondValue:
    return 1
  return 0

proc upperPosition(values: seq[int], target: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = (low + high) div 2
    if values[middle] <= target:
      low = middle + 1
    else:
      high = middle
  return low
```

The comparator breaks first-coordinate ties by second coordinate.
The upper bound keeps equal values in one run.
Both helpers run in logarithmic time per pair.

**Case loop.** The sorted pairs feed the tails, and one line per case is buffered.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let endpointCount = nextInt(inputData, scanPos)
  var firstCoordinates = newSeq[int](endpointCount)
  var secondCoordinates = newSeq[int](endpointCount)
  for endpointIndex in 0 .. endpointCount - 1:
    firstCoordinates[endpointIndex] = nextInt(inputData, scanPos)
  for endpointIndex in 0 .. endpointCount - 1:
    secondCoordinates[endpointIndex] = nextInt(inputData, scanPos)
  var endpointPairs = newSeq[tuple[firstValue: int, secondValue: int]](endpointCount)
  for endpointIndex in 0 .. endpointCount - 1:
    endpointPairs[endpointIndex] = (firstCoordinates[endpointIndex], secondCoordinates[endpointIndex])
  endpointPairs.sort(comparePairs)
  var tailValues = newSeq[int]()
  for pairIndex in 0 .. endpointCount - 1:
    let currentValue = endpointPairs[pairIndex].secondValue
    let insertAt = upperPosition(tailValues, currentValue)
    if insertAt == tailValues.len:
      tailValues.add currentValue
    else:
      tailValues[insertAt] = currentValue
  appendOutput($tailValues.len)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The two coordinate arrays are read before pairing.
Sorting costs O(n log n), and each tail update costs O(log n).
The final flush writes every buffered answer once.

## Complexity

Sorting and tail updates dominate each case.

| phase | time | space |
|---|---|---|
| input read | one pass over coordinates | one input string |
| pair sort | O(n log n) comparisons | n pairs |
| tail scan | O(n log n) binary searches | up to n tails |
| output | one line per case | block buffer |

The sort and scan share the same order of growth.

| measure | Big O |
|---|---|
| time per case | O(n log n) |
| space per case | O(n) |

A pairwise crossing test would spend O(n^2) time per case, which cannot handle n = 100000.

The patience order turns the geometry into one short sorted scan.
