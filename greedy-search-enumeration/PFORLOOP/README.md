# PFORLOOP — For Loops Challenge (SPOJ)

<https://www.spoj.com/problems/PFORLOOP/>

## Problem

A file once held the output of C++ loops that printed consecutive integers, and someone shuffled those integers across lines. Recover every maximal block of consecutive integers and print one loop per block, ordered by value.

Input has many lines. Each line holds at most 1000 space-separated integers in `[0, 1000000000]`, with no repeated integer. Output one line per block in ascending order. The exact format appears in the sample below.

| item | bound |
|---|---|
| integers per line | at most 1000 |
| integer range | 0 to 1000000000 |
| repeated integers | none |
| judge limit | 2000 ms, 1536 MB |

The sample from the statement:

```
9 6 100 1 3 105
2 4 101 102 103 104 5 7 8
```

```
for (int i = 1; i <= 9; i++) cout << i << " ";
for (int i = 100; i <= 105; i++) cout << i << " ";
```

## Idea

Sorting the scattered numbers makes each original loop appear as a contiguous run, like arranging shuffled playing cards into consecutive stacks. The algorithm sorts all integers, then walks the sorted list once and emits a loop whenever the next value is not one larger. Sorting costs `O(N log N)` and the walk costs `O(N)`. Testing every pair of numbers to find neighbors would cost `O(N^2)`. Sorting turns a reconstruction puzzle into one short scan.

## Why It Works

1. Each original loop printed consecutive integers, so its members form a run in the sorted list.
2. Sorting places every member of a run beside its neighbors.
3. Distinct integers make a gap of exactly one the reliable run boundary.
4. A run from its first value to its last value recreates one original loop.
5. Ascending order of the sorted list matches the required output order.

| term | meaning |
|---|---|
| `numberList` | all integers from every input line, sorted |
| `runStart` | first value position of the current run |
| `runEnd` | last value position of the current run |
| `loopPrefix` | fixed text before the first bound |
| `loopSuffix` | fixed text after the second bound |

The table names each value the scan uses.

A script trace of the sample follows.

| sorted values | gap to next | action |
|---|---|---|
| 1 2 3 4 5 6 7 8 9 | 100 - 9 = 91 | emit loop 1 to 9 |
| 100 101 102 103 104 105 | end of list | emit loop 100 to 105 |

The two emitted loops match the sample output exactly.

## Code

**Input and sorting.** The hand scanner collects every integer and sorts the list.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const loopPrefix = "for (int i = "
const loopMiddle = "; i <= "
const loopSuffix = "; i++) cout << i << \" \";\n"

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

proc compareNumbers(firstValue: int, secondValue: int): int =
  if firstValue < secondValue:
    return -1
  if firstValue > secondValue:
    return 1
  return 0

var numberList: seq[int] = @[]
while true:
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  numberList.add nextInt(inputData, scanPos)

numberList.sort(compareNumbers)
```

The scan skips line breaks and spaces before each number.
The explicit comparator works on both Nim compilers.
Sorting puts every run into consecutive positions.

**Run emission.** One pass writes a loop for each maximal run.

```nim
var runStart = 0
while runStart < numberList.len:
  var runEnd = runStart
  while runEnd + 1 < numberList.len and numberList[runEnd + 1] == numberList[runEnd] + 1:
    runEnd += 1
  appendOutput(loopPrefix & $numberList[runStart] & loopMiddle & $numberList[runEnd] & loopSuffix)
  runStart = runEnd + 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each pass advances `runEnd` while the next value continues the run.
The output buffer flushes by block, not by line.
The final write flushes any remaining text.

## Complexity

The work splits into reading, sorting, and emitting runs.

| phase | time | space |
|---|---|---|
| input read | one pass over all integers | one input string |
| sort | `O(N log N)` comparisons | one integer list |
| run emission | one pass over the sorted list | block output buffer |

The list size drives both time and space.

| measure | Big O |
|---|---|
| time | `O(N log N)` |
| space | `O(N)` |

A pairwise neighbor search would take `O(N^2)` instead of one sort and one scan. Sorting keeps reconstruction short even for the largest allowed input.
