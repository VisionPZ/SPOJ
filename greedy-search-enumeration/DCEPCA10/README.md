# DCEPCA10 — MAD (SPOJ)
<https://www.spoj.com/problems/DCEPCA10/>

## Problem

Make more than half of the values equal to their shared median, and the median of their absolute deviations becomes zero. Count the fewest changes needed to reach that state.

Input starts with the number of test cases. Each test case gives the size, then the values on one line. Output one line per test case with the minimum change count.

| item | bound |
|---|---|
| test cases T | 1 to 10 |
| values per case N | 1 to 100000 |
| value range | 0 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

A zero deviation occurs only where a value equals the median.

Sample input:

```
2
5
4 5 3 1 2
10
5 5 5 254 5 5 768 5 5 5
```

Sample output:

```
2
0
```

## Idea

Treat the median as a majority vote: once one value holds a majority, it wins automatically, like electing a candidate with over half the ballots. Sort the values and find the longest equal run. A run of length `longestRun` needs `requiredRun - longestRun` new members, where `requiredRun` is half the size plus one. Recomputing medians after every trial change repeats work; counting equal values answers the question directly.

Counting one sorted run costs constant time per value.

## Why It Works

1. A deviation equals zero exactly when its value equals the median.
2. The median of nonnegative deviations is zero only when over half of them are zero.
3. Over half of the values must therefore equal the median.
4. A value with over half the positions is itself the median, so no other candidate competes.
5. Changing unrelated values cannot help; only copies of the chosen value matter.

| term | meaning |
|---|---|
| `requiredRun` | `elementCount div 2 + 1`, the majority size |
| `longestRun` | length of the longest equal run after sorting |
| `changesNeeded` | `requiredRun - longestRun`, clipped at zero |
| `values` | sorted values of one test case |

The worked example uses the first sample case with five values.

| step | visible value |
|---|---|
| sorted values | 1 2 3 4 5 |
| longest equal run | 1 |
| required majority | 5 div 2 + 1 = 3 |
| changes needed | 3 - 1 = 2 |

Clipping at zero handles cases that already hold a majority.

## Code

**Input and scanner.** The reader loads every line and parses integers by hand.

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
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The scanner skips separators and builds each value digit by digit.
All input lines join one string before parsing starts.

**Output helper and comparator.** Buffered writes avoid a system call per number.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc compareValues(leftValue, rightValue: int): int =
  if leftValue < rightValue:
    return -1
  if leftValue > rightValue:
    return 1
  return 0
```

The buffer flushes once it reaches one hundred twenty-eight kilobytes.
The comparator supplies the ordering that Nim's sort needs.

**Run scan.** Sorting groups equal values, and one pass measures the best group.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  var values = newSeq[int](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    values[elementIndex] = nextInt(inputData, scanPos)
  values.sort(compareValues)
  var longestRun = 1
  var currentRun = 1
  for elementIndex in 1 .. elementCount - 1:
    if values[elementIndex] == values[elementIndex - 1]:
      currentRun += 1
      if currentRun > longestRun:
        longestRun = currentRun
    else:
      currentRun = 1
  let requiredRun = elementCount div 2 + 1
  var changesNeeded = requiredRun - longestRun
  if changesNeeded < 0:
    changesNeeded = 0
  appendOutput($changesNeeded)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Equal neighbors extend the current run by one.
A different value restarts the run at one.
The final line flushes any remaining buffered text.

## Complexity

Sorting dominates the work for each test case.

| phase | time | space |
|---|---|---|
| input read | one pass over all values | one input string |
| sorting | N log N comparisons | array of N integers |
| run scan | one pass over sorted values | constant |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(N log N) |
| space per case | O(N) |

Testing every possible median would multiply the run scan by N.

Sorting once and scanning once keeps each case near linearithmic time.
