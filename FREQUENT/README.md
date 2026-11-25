# FREQUENT — Frequent values (SPOJ)

<https://www.spoj.com/problems/FREQUENT/>

## Problem

For each range in a sorted list, report how many times the most common value appears there. The list never changes, so the answer depends on runs of equal neighbours.

Input: several test cases. Each starts with n and q, then n sorted integers, then q pairs of one-based indices i and j. A line containing 0 ends the input. Output: one maximum frequency per query, on its own line.

| item | bound |
|---|---|
| list size n | 1 to 100000 |
| queries q per case | 1 to 100000 |
| values | -100000 to 100000 |
| judge limit | 1000 ms, 1536 MB |

The query count drives the design, so each query needs constant work.

Sample input:

```
10 3
-1 -1 1 1 1 1 3 10 10 10
2 3
1 10
5 10
0
```

Sample output:

```
1
4
3
```

The input list contains four runs of equal values.

## Idea

Group equal neighbours into runs, like stacking identical books into piles. A range starts and ends inside two runs, and the full runs between them form a static maximum question. A sparse table answers that maximum in one comparison pair.

The algorithm builds the runs once and precomputes maxima for every power-of-two span. Each query costs two binary searches plus one table lookup. A naive scan counts every value in every range and costs O(n) per query.

Splitting each range into two partial runs and one inner maximum avoids rescanning the list.

## Why It Works

1. Sorted input keeps every equal block contiguous.
2. Inside one run, the answer is the number of chosen positions.
3. Inside a range spanning several runs, the answer is the largest partial run or full run.
4. Run starts are sorted, so binary search finds the two boundary runs.
5. Sparse table entry (k, r) stores the largest run length among 2 to the power k runs starting at r.
6. Two overlapping power-of-two blocks cover any inner run interval.

| term | meaning |
|---|---|
| `runStarts` | first position of each run |
| `runLengths` | number of equal values in each run |
| `table` | sparse table of maximum run lengths |
| `bestCount` | answer for the current query |

The four terms cover the parse, the table and the query.

Here is the run breakdown for the sample from `gen.py`:

| run | positions | length |
|---|---|---|
| 1 | 1 to 2 | 2 |
| 2 | 3 to 6 | 4 |
| 3 | 7 to 7 | 1 |
| 4 | 8 to 10 | 3 |

Query 1 to 10 takes max(2, 4, 1, 3) and returns 4.

## Code

**Input and query helpers.** The reader loads all stdin, accepts negative values and binary-searches run starts.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc runIndexAt(starts: seq[int], length: int, position: int): int =
  var low = 0
  var high = length - 1
  while low <= high:
    let middle = (low + high) div 2
    if starts[middle] <= position:
      low = middle + 1
    else:
      high = middle - 1
  return high
```

The minus branch handles negative values in the input list.
One output buffer collects all query answers.
Binary search returns the run containing a position.

**Case loop and sparse table.** The driver builds runs, fills the table and answers every query.

```nim
while true:
  let numberCount = nextInt(inputData, scanPos)
  if numberCount == 0:
    break
  let queryCount = nextInt(inputData, scanPos)
  var values = newSeq[int](numberCount)
  for valueIndex in 0 .. numberCount - 1:
    values[valueIndex] = nextInt(inputData, scanPos)
  var runStarts = newSeq[int](numberCount)
  var runLengths = newSeq[int](numberCount)
  var runCount = 0
  var valueIndex = 0
  while valueIndex < numberCount:
    runStarts[runCount] = valueIndex
    var runEnd = valueIndex + 1
    while runEnd < numberCount and values[runEnd] == values[valueIndex]:
      runEnd += 1
    runLengths[runCount] = runEnd - valueIndex
    runCount += 1
    valueIndex = runEnd
  var logarithms = newSeq[int](runCount + 1)
  for span in 2 .. runCount:
    logarithms[span] = logarithms[span div 2] + 1
  let levelCount = logarithms[runCount] + 1
  var table = newSeq[seq[int]](levelCount)
  table[0] = runLengths
  for level in 1 .. levelCount - 1:
    let halfSpan = 1 shl (level - 1)
    let entryCount = runCount - (1 shl level) + 1
    var row = newSeq[int](entryCount)
    for entryIndex in 0 .. entryCount - 1:
      let leftValue = table[level - 1][entryIndex]
      let rightValue = table[level - 1][entryIndex + halfSpan]
      if leftValue > rightValue:
        row[entryIndex] = leftValue
      else:
        row[entryIndex] = rightValue
    table[level] = row
  for queryIndex in 0 .. queryCount - 1:
    let leftPosition = nextInt(inputData, scanPos) - 1
    let rightPosition = nextInt(inputData, scanPos) - 1
    let leftRun = runIndexAt(runStarts, runCount, leftPosition)
    let rightRun = runIndexAt(runStarts, runCount, rightPosition)
    var bestCount: int
    if leftRun == rightRun:
      bestCount = rightPosition - leftPosition + 1
    else:
      let leftTail = runStarts[leftRun] + runLengths[leftRun] - leftPosition
      let rightHead = rightPosition - runStarts[rightRun] + 1
      bestCount = leftTail
      if rightHead > bestCount:
        bestCount = rightHead
      let innerLeft = leftRun + 1
      let innerRight = rightRun - 1
      if innerLeft <= innerRight:
        let span = innerRight - innerLeft + 1
        let level = logarithms[span]
        let offset = innerRight - (1 shl level) + 1
        var innerBest = table[level][innerLeft]
        let secondValue = table[level][offset]
        if secondValue > innerBest:
          innerBest = secondValue
        if innerBest > bestCount:
          bestCount = innerBest
    appendOutput($bestCount)
    outputBuffer.add '\n'
```

The run pass scans the sorted list once.
Each table row halves the previous span.
Partial runs cover the two query ends.
The final flush writes all answers.

## Complexity

Preprocessing runs once pays for every later query.

| phase | time | space |
|---|---|---|
| input read | one pass over input tokens | one input string |
| run build | one pass over n values | two arrays of n |
| sparse table | one pass per level | O(n log n) entries |
| queries | two searches and one lookup | block buffer |

The table build is the largest one-time cost.

| measure | Big O |
|---|---|
| preprocessing | O(n log n) time and space |
| per query | O(log n) time |
| total | O(n log n + q log n) |

Scanning each range directly costs O(n) per query, while the sparse table costs O(log n).
The binary searches and one comparison pair keep every query within the time limit.
