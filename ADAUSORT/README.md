# ADAUSORT — Ada and Unstable Sort (SPOJ)

<https://www.spoj.com/problems/ADAUSORT/>

## Problem

Sort the input values, but reverse the original order of every group of equal values. Print the original 1-based index of each element in that final order, one line per test case.

Each test case starts with `N`, followed by `N` values. Input ends at end of file. Output has `N` space-separated indices on one line.

| item | bound |
|---|---|
| elements N per case | 1 to 100000 |
| each value | 1 to 100000 |
| test cases | until end of file |
| judge limit | 1000 ms, 1536 MB |

The value bound on `N` makes a comparison sort the natural choice.

Sample input:

```
4
1 2 3 4
```

Sample output:

```
1 2 3 4
```

## Idea

Reversing each group of equal values is like a row of twins turning around in place, so the row still has the right order but every twin pair swaps. The algorithm sorts pairs of value and original index with value ascending and index descending. Sorting costs O(N log N) per case, while a stable sort plus a separate repair pass costs more work. One comparator handles distinct values and reversed duplicates together.

## Why It Works

1. Ascending value order gives the sorted sequence required by the problem.
2. Equal values form one group, and reversing their indices changes every pair's mutual order.
3. `compareIndexed` compares values first, then compares original indices in reverse.
4. Reading `indexedValues` after sorting yields the permutation to print.
5. `hasMoreNumbers` reads test cases until the input string is exhausted.

| term | meaning |
|---|---|
| `indexedValues` | each value paired with its 1-based original position |
| `originalIndex` | position of an element in the input |
| `compareIndexed` | value ascending, then original index descending |
| `elementCount` | length of the current test case |

For `5 5 2 2 3`, the value `2` group has indices `3, 4` and reverses to `4, 3`. The value `3` group keeps index `5`, and the value `5` group reverses to `2, 1`. The printed line is `4 3 5 2 1`.

## Code

**Input and comparator.** The reader scans integers until end of file, and the comparator encodes both sort keys.

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

proc hasMoreNumbers(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len and (data[scanIndex] < '0' or data[scanIndex] > '9'):
    scanIndex += 1
  return scanIndex < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type IndexedValue = object
  value: int
  originalIndex: int

proc compareIndexed(leftItem: IndexedValue, rightItem: IndexedValue): int =
  if leftItem.value != rightItem.value:
    leftItem.value - rightItem.value
  else:
    rightItem.originalIndex - leftItem.originalIndex
```

The hand scanner skips whitespace before each number.
The index field preserves the information a usual sort discards.
The second comparison key forces a full reversal inside each equal group.

**Sort and print.** Each case is sorted once and written as one line.

```nim
while hasMoreNumbers(inputData, scanPos):
  let elementCount = nextInt(inputData, scanPos)
  var indexedValues = newSeq[IndexedValue](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    indexedValues[elementIndex].value = nextInt(inputData, scanPos)
    indexedValues[elementIndex].originalIndex = elementIndex + 1
  indexedValues.sort(compareIndexed)
  for itemIndex in 0 .. elementCount - 1:
    if itemIndex > 0:
      outputBuffer.add ' '
    appendOutput($(indexedValues[itemIndex].originalIndex))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Original indices are assigned before the sort.
Spaces are inserted between entries, not after the last one.
The buffer flushes once after all test cases.

## Complexity

Sorting is the main cost, and output is linear in the number of entries.

| phase | time | space |
|---|---|---|
| input read | one pass over all values | one input string |
| sort per case | `O(N log N)` | `N` indexed pairs |
| output | one line per case | block buffer |

The sort dominates the running time for large cases.

| measure | Big O |
|---|---|
| time | `O(N log N)` per test case |
| space | `O(N)` |

A stable sort followed by a scan to flip each group would need extra passes, so the single comparator is the deciding gain. The reversal falls out of the sort key without post-processing.
