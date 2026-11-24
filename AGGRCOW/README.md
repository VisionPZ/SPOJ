## Problem

Read several test cases. Each case gives N stall positions and a cow count C. Place the cows in distinct stalls so the smallest distance between any two cows is as large as possible. Print that largest minimum distance for each case.

The statement sets these bounds:

| Quantity | Bound |
| --- | --- |
| Test cases | not stated |
| Stalls per case | 2 to 100000 |
| Cows per case | 2 to N |
| Stall position | 0 to 1000000000 |
| Time limit | 2000 ms |
| Memory limit | 1536 MB |

The stall count drives the design, since each feasibility test scans every stall.

## Idea

Sort the stalls and binary search the largest workable gap. A gap works when C cows fit with every pair at least that far apart. Place each cow at the leftmost stall that keeps the gap. One test therefore scans the sorted stalls once. One answer costs O(N log R) time for a position range of R. Trying every subset of stalls costs far more.

## Why It Works

Moving the first cow to an earlier stall never reduces the room left for later cows. So first-fit placement succeeds whenever any placement succeeds. If a gap works, every smaller gap also works, and binary search applies.

The search interval is half open. It starts at zero and ends one past the span from the lowest stall to the highest stall. A stall after `lastIndex` is usable when `stalls[i] - stalls[lastIndex] >= gap`. The midpoint `midGap` chooses the upper middle, so each step shrinks the interval and never stalls.

The script in `gen.py` places cows greedily on the sorted sample stalls 1, 2, 4, 8, 9:

| Gap | Placed stalls | Cow count |
| --- | --- | --- |
| 2 | 1, 4, 8 | 3 |
| 3 | 1, 4, 8 | 3 |
| 4 | 1, 8 | 2 |

Three cows fit at gap 3 but not at gap 4, so the answer is 3.

## Code

```nim
{.push checks: off.}
{.passC: "-O3".}

import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
```

The read loop stops when stdin ends. The scanner skips non-digits, which absorbs every line break. Scanning one buffer costs one pass over the input bytes.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

A flush happens once the buffer passes its byte limit. Reusing the buffer with `setLen 0` avoids a fresh string per answer. The cost is one stream write per block.

```nim
proc canPlace(stalls: seq[int], cowCount, gap: int): bool =
  var placedCount = 1
  var lastIndex = 0
  for i in 1..<stalls.len:
    if stalls[i] - stalls[lastIndex] >= gap:
      placedCount += 1
      lastIndex = i
      if placedCount >= cowCount: return true
  return cowCount <= 1
```

The loop visits each stall once, starting after the first. The `>=` test accepts a stall exactly one gap away. The early return stops work once enough cows fit. The worst cost is O(N) per test.

```nim
var stalls: seq[int] = @[]

let caseCount = nextInt(inputData, scanPos)
for j in 0..<caseCount:
  let stallCount = nextInt(inputData, scanPos)
  let cowCount = nextInt(inputData, scanPos)
  stalls.setLen(stallCount)
  for i in 0..<stallCount:
    stalls[i] = nextInt(inputData, scanPos)
  stalls.sort(system.cmp[int])
  var lowGap = 0
  var highGap = stalls[stallCount - 1] - stalls[0] + 1
  while lowGap < highGap:
    let midGap = (lowGap + highGap + 1) div 2
    if canPlace(stalls, cowCount, midGap):
      lowGap = midGap
    else:
      highGap = midGap - 1
  appendOutput($(lowGap))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sort orders stalls once per case, at O(N log N). The binary search runs O(log R) times. `setLen` reuses one stall array across cases. The final write flushes any remaining output.

## Complexity

Reading and scanning take time linear in the input size. Sorting costs O(N log N) per case. Each feasibility test costs O(N), and the search runs O(log R) times. The total is O(N log N + N log R) time and O(N) space per case. A subset search would examine exponentially many stall assignments.
