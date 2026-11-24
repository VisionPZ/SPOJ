## Problem

The input gives distinct points on a sheet. A flat broken line is a left-to-right stroke whose segments each stay within 45 degrees of the x axis. Find the fewest such lines that cover every point. Write u for y minus x and v for y plus x. Print one integer per test case.

| Quantity | Bound |
| --- | --- |
| Test cases | not stated |
| Points per case | at most 30000 |
| x and y | 0 to 30000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The point count drives the design, so each case needs a subquadratic method.

## Idea

A flat broken line is the graph of a function whose slope magnitude stays at most one. Two points fit on one line when their vertical gap never exceeds their horizontal gap. That condition becomes u never rising and v never falling along a line. By Dilworth's theorem the fewest lines equal the largest group of points with u rising and v rising. The program sorts by u and v, then counts that group with a patience-sorting scan.

Cost per point: one comparison in the sort and one logarithmic step in the scan.

## Why It Works

Take two points with x coordinates x1 < x2 and y coordinates y1 and y2. One line covers both when the absolute gap |y2 - y1| stays at most x2 - x1. Split that inequality into its two sides.

u2 <= u1 follows from y2 - x2 <= y1 - x1.
v2 >= v1 follows from y1 + x1 <= y2 + x2.

These two rules form a partial order. One line covers a chain in this order, so the answer is a minimum chain cover. Dilworth's theorem equates that cover with the largest antichain. Two points are incomparable exactly when u rises and v rises together. The answer is therefore the longest subsequence with both values strictly rising.

The program packs the two values into one integer key. The upper bits hold u plus 30000. The lower bits hold 65535 minus v. Ascending keys place u in rising order and v in falling order for equal u. That tie rule keeps two points with equal u out of one rising subsequence.

The scan keeps `lisTails`, the smallest last value seen for each subsequence length. A binary search finds the first entry at least as large as the new v. The scan replaces that entry, or appends v when no entry qualifies. The final length is the answer.

The script transforms the sample points as follows.

| point | u = y - x | v = y + x |
| --- | --- | --- |
| (1, 6) | 5 | 7 |
| (10, 8) | -2 | 18 |
| (1, 5) | 4 | 6 |
| (2, 20) | 18 | 22 |
| (4, 4) | 0 | 8 |
| (6, 2) | -4 | 8 |

The point (10, 8) has u = -2 and v = 18 in that table.

After sorting, the scan reads v in this order.

| point | u | v | `lisTails` after |
| --- | --- | --- | --- |
| (6, 2) | -4 | 8 | 8 |
| (10, 8) | -2 | 18 | 8, 18 |
| (4, 4) | 0 | 8 | 8, 18 |
| (1, 5) | 4 | 6 | 6, 18 |
| (1, 6) | 5 | 7 | 6, 7 |
| (2, 20) | 18 | 22 | 6, 7, 22 |

The tails end at length 3, so three lines cover the sample.

## Code

The scanner skips the blank lines between cases and reads all input once.

```nim
import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const coordBound = 30000
const keyShift = 16
const keyMask = (1 shl keyShift) - 1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The read loop runs once per input line and appends one newline each time. The digit value subtracts `firstDigitValue`, so the scanner handles non-negative coordinates only. Parsing visits each character once and costs O(input bytes).

The two sequences are reused across cases, and the output buffer flushes in blocks.

```nim
var sortKeys: seq[int] = @[]
var lisTails: seq[int] = @[]

proc compareKey(left, right: int): int =
  if left < right: return -1
  if left > right: return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`flushBlockBytes` caps memory at 256 KiB and avoids one write per answer. `compareKey` gives the sort a plain ascending order. Reusing both sequences costs O(1) per case and no per-case allocation.

The key builder runs once per point, and the sort orders the keys.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let pointCount = nextInt(inputData, scanPos)
  sortKeys.setLen(pointCount)
  for i in 0..<pointCount:
    let x = nextInt(inputData, scanPos)
    let y = nextInt(inputData, scanPos)
    let upValue = y - x
    let downValue = y + x
    sortKeys[i] = (upValue + coordBound) * (1 shl keyShift) + (keyMask - downValue)

  sort(sortKeys, compareKey)
```

The loop bound equals the point count of the current case. Storing 65535 minus v makes v fall inside each equal-u group. Key building is linear; the sort costs O(n log n).

The scan finds the rising subsequence and appends one answer line per case.

```nim
  lisTails.setLen(0)
  for i in 0..<pointCount:
    let downValue = keyMask - (sortKeys[i] and keyMask)
    var lo = 0
    var hi = lisTails.len
    while lo < hi:
      let mid = (lo + hi) div 2
      if lisTails[mid] < downValue:
        lo = mid + 1
      else:
        hi = mid
    if lo == lisTails.len:
      lisTails.add downValue
    else:
      lisTails[lo] = downValue

  appendOutput($(lisTails.len))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The strict test at lo keeps equal v values out of one subsequence. The final write flushes any bytes left below the block size. Each point costs one binary search, so the scan costs O(n log n).

## Complexity

Reading costs O(total input bytes) once. Each case builds keys in O(n), sorts in O(n log n), and scans in O(n log n). The total is O(total input bytes + sum of n log n over cases). Space is O(n) for `sortKeys` and `lisTails`, plus the 256 KiB output buffer. A pairwise method that builds a matching would take cubic time per case.
