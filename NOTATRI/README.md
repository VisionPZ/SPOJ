# NOTATRI — Not a Triangle (SPOJ)

<https://www.spoj.com/problems/NOTATRI/>

## Problem

Count unordered triples of sticks whose lengths cannot form a triangle. A triple forms a triangle when the two shorter lengths sum to at least the longest length, so invalid triples have a strict inequality.

| item | bound |
|---|---|
| sticks N | 3 to 2000 |
| length Li | 1 to 1000000 |
| test cases | until N = 0 |
| judge limit | 1000 ms, 1536 MB |

Input ends with a zero on its own line.

Sample input:

```
3
4 2 10
3
1 2 3
4
5 2 9 6
0
```

Sample output:

```
1
0
2
```

## Idea

Sort the sticks, then treat each stick as the longest side and count pairs that fall short of it, like checking every possible shelf width against a fixed board. A two-pointer scan finds those pairs in one pass per longest side. Sorting costs O(N log N), and the scan costs O(N^2). Trying all triples would cost O(N^3).

| term | meaning |
|---|---|
| `stickLengths` | lengths in ascending order |
| `longestIndex` | index of the candidate longest side |
| `middleIndex` | index of the middle side in a pair |
| `smallerIndex` | first index whose length passes the sum test |
| `losingTriples` | number of triples that cannot form a triangle |

Each longest side gets one left-to-right pointer pass.

## Why It Works

1. After sorting, any triple has its longest side at the highest index.
2. For a fixed longest side k and middle side j, a valid pair needs Li[j] + Li[i] >= Li[k] for the smaller side i.
3. Lengths increase with the index, so the failing smaller indices form a prefix.
4. The prefix length for one j is found by advancing one pointer across all j values.
5. The count is clipped to j when the pointer passes the middle side.
6. Summing those prefix lengths over every k and j counts each invalid triple once.

| term | meaning |
|---|---|
| `smallerIndex` | size of the failing prefix for the current pair |
| strict inequality | degenerate triangles count as triangles |

The prefix property turns a triple loop into a pair loop.

A worked example for lengths 2, 5, 6, 9:

```
longest 6: pairs (2,5) sum 7 -> no failure
longest 9:
  middle 5: smaller 2 -> 2 + 5 = 7 < 9 -> 1 failure
  middle 6: smaller 2 -> 2 + 6 = 8 < 9 -> 1 failure
  middle 6 is the last pair
total 2
```

The trace matches the sample answer for that test case.

## Code

**Input and sorting.** The reader loads one case at a time and sorts it in place.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc sortLengths(values: var seq[int], lowIndex: int, highIndex: int) =
  if lowIndex >= highIndex:
    return
  var leftIndex = lowIndex
  var rightIndex = highIndex
  let pivotValue = values[(lowIndex + highIndex) div 2]
  while leftIndex <= rightIndex:
    while values[leftIndex] < pivotValue:
      leftIndex += 1
    while values[rightIndex] > pivotValue:
      rightIndex -= 1
    if leftIndex <= rightIndex:
      swap values[leftIndex], values[rightIndex]
      leftIndex += 1
      rightIndex -= 1
  if lowIndex < rightIndex:
    sortLengths(values, lowIndex, rightIndex)
  if leftIndex < highIndex:
    sortLengths(values, leftIndex, highIndex)
```

The quicksort uses an explicit pivot with no generic comparator.
Lengths fit in a machine integer.
A zero stick count ends the input.

**Counting and output.** The two-pointer loop counts failing pairs for each longest side.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let stickCount = nextInt(inputData, scanPos)
  if stickCount == 0:
    break
  var stickLengths = newSeq[int](stickCount)
  for stickIndex in 0 .. stickCount - 1:
    stickLengths[stickIndex] = nextInt(inputData, scanPos)
  sortLengths(stickLengths, 0, stickCount - 1)
  var losingTriples: int64 = 0
  for longestIndex in 2 .. stickCount - 1:
    var smallerIndex = 0
    var middleIndex = longestIndex - 1
    while middleIndex >= 1:
      while smallerIndex < middleIndex and
            stickLengths[smallerIndex] + stickLengths[middleIndex] < stickLengths[longestIndex]:
        smallerIndex += 1
      losingTriples += int64(min(smallerIndex, middleIndex))
      middleIndex -= 1
  appendOutput($losingTriples)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The pointer only moves forward within one longest side.
The total uses int64 because C(2000, 3) exceeds a signed 32-bit range.
One buffered line is written per case.

## Complexity

Sorting and the pair scan set the cost.

| phase | time | space |
|---|---|---|
| input read | one pass over stick lengths | one input string |
| sort | O(N log N) per case | array of N integers |
| pair scan | O(N^2) per case | constant |
| output | one line per case | block buffer |

The pair scan dominates for large N.

| measure | Big O |
|---|---|
| time | O(N^2) per case |
| space | O(N) |

A brute-force triple check would take O(N^3) per case.

The sorted order and the moving pointer give the full count in quadratic time.
