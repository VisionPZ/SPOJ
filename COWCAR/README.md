# COWCAR — Cow Cars (SPOJ)

<https://www.spoj.com/problems/COWCAR/>

## Problem

Choose the largest group of cows that can drive while each keeps at least the minimum speed. A cow loses speed for every cow ahead of it, and the highway has several lanes.

The first line gives four integers: cow count `N`, lane count `M`, speed loss `D`, and minimum speed `L`. The next `N` lines give the top speeds `S`. Print one integer, the largest legal group size.

| item | bound |
|---|---|
| cows N | 1 to 50000 |
| lanes M | 1 to N |
| speed loss D | 0 to 5000 |
| speed limit L | 1 to 1000000 |
| top speed S | 1 to 1000000 |
| judge limit | 1000 ms, 1536 MB |

The cow count drives the need for a fast sort.

Sample input:

```
3 1 1 5
5
7
5
```

Sample output:

```
2
```

## Idea

Think of filling lanes with cars from slowest to fastest, like stacking books so the heavier ones go underneath. A cow placed at rank `r` in a lane loses `D*r` speed, and ranks repeat every `M` cows. Sort speeds once, then admit a cow when its reduced speed clears the limit. A linear scan after sorting beats trying every subset of cows. Take the sorted scan as the whole algorithm.

## Why It Works

1. Sorting speeds ascending lets weak cows take the low ranks and strong cows take the high ranks.
2. After `k` cows are admitted, the next cow sits at rank `k div M` in its lane.
3. Its effective speed is `S - D*(k div M)`.
4. Admitting a cow when this value reaches `L` is safe, because later cows are at least as fast.
5. Rejecting a cow at rank `r` is safe, because every later cow faces a rank at least as large.

| term | meaning |
|---|---|
| `laneRank` | `admittedCows div laneCount`, the cow's position in its lane |
| `reducedSpeed` | top speed minus `slowdown` times `laneRank` |
| `admittedCows` | number of cows accepted so far |

The three terms give the whole decision rule.

A script trace for the sample uses speeds `5, 5, 7`, one lane, loss `1`, limit `5`. Rank `0` accepts speed `5`, rank `1` rejects speed `5`, and rank `1` accepts speed `7`, giving `2`.

That trace matches the sample output.

## Code

**Input and scanning.** The hand reader loads stdin once and extracts the header and speeds.

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

The scanner skips line breaks between speeds.
No extra token is read past the last cow.
One pass over the input string suffices.

**Merge sort.** A bottom-up merge sort orders speeds without a custom comparator in the standard library.

```nim
proc sortSpeeds(values: var seq[int]) =
  let valueCount = values.len
  if valueCount < 2:
    return
  var buffer = newSeq[int](valueCount)
  var span = 1
  while span < valueCount:
    var start = 0
    while start < valueCount:
      var middle = start + span
      if middle > valueCount:
        middle = valueCount
      var finish = start + 2 * span
      if finish > valueCount:
        finish = valueCount
      var leftCursor = start
      var rightCursor = middle
      var writeCursor = start
      while leftCursor < middle and rightCursor < finish:
        if values[leftCursor] <= values[rightCursor]:
          buffer[writeCursor] = values[leftCursor]
          leftCursor += 1
        else:
          buffer[writeCursor] = values[rightCursor]
          rightCursor += 1
        writeCursor += 1
      while leftCursor < middle:
        buffer[writeCursor] = values[leftCursor]
        leftCursor += 1
        writeCursor += 1
      while rightCursor < finish:
        buffer[writeCursor] = values[rightCursor]
        rightCursor += 1
        writeCursor += 1
      start = finish
    swap values, buffer
    span = span * 2
```

Span doubles until it covers the whole list.
The two sequences swap roles after each pass.
Sorting costs `O(N log N)` time.

**Admission scan.** One pass assigns ranks and counts accepted cows.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let cowCount = nextInt(inputData, scanPos)
let laneCount = nextInt(inputData, scanPos)
let slowdown = nextInt(inputData, scanPos)
let limitSpeed = nextInt(inputData, scanPos)
var speeds = newSeq[int](cowCount)
for cowIndex in 0 .. cowCount - 1:
  speeds[cowIndex] = nextInt(inputData, scanPos)
sortSpeeds(speeds)
var admittedCows = 0
for speedIndex in 0 .. cowCount - 1:
  let laneRank = admittedCows div laneCount
  let reducedSpeed = int64(speeds[speedIndex]) - int64(slowdown) * int64(laneRank)
  if reducedSpeed >= int64(limitSpeed):
    admittedCows += 1
appendOutput($admittedCows)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Rank uses the accepted count, not the loop index.
Products stay in `int64` to avoid overflow.
The answer is written once after the scan.

## Complexity

Sorting dominates one linear scan, so cost grows with `N log N`.

| phase | time | space |
|---|---|---|
| input read | one pass over speeds | one input string |
| merge sort | `N log N` comparisons | one extra speed buffer |
| admission scan | one check per cow | constant |
| output | one line | block buffer |

The speed list and its merge buffer dominate memory.

| measure | Big O |
|---|---|
| time | O(N log N) |
| space | O(N) |

Trying every subset of cows would grow exponentially. Sorting once keeps the problem tractable at 50000 cows.
