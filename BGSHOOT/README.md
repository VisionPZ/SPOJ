# BGSHOOT — Shoot and kill (SPOJ)

<https://www.spoj.com/problems/BGSHOOT/>

## Problem

Each animal is available during one closed time interval. For each shooting window, report the largest number of intervals that share a single moment inside that window.

Input starts with the animal count N. The next N lines give the start X and end Y of one animal. A line with Q follows, then Q lines give the window bounds L and R. Print one maximum overlap count per window, in input order.

| item | bound |
|---|---|
| animals N | 1 to 100000 |
| queries Q | 1 to 100000 |
| times X, Y, L, R | 1 to 1000000000 |
| judge limit | 500 ms, 1536 MB |

All bounds are inclusive, so an animal ending at Y is still available at Y.

Sample input:

```
4
1 2
2 3
4 5
6 7
4
1 5
2 3
4 7
5 7
```

Sample output:

```
2
2
1
1
```

## Idea

Overlap only changes where an interval starts or ends, like people entering and leaving a room. Sweep those change points once, then store the overlap level for each stretch between them. A segment tree answers each window by taking the maximum stored level over its stretch.

The sweep costs one sort plus one pass per animal. A window costs logarithmic time instead of scanning every time value. Asking every candidate time directly would repeat the same count work for each query.

## Why It Works

1. An animal is present at moment t exactly when X ≤ t ≤ Y.
2. Adding one at X and subtracting one at Y + 1 makes a running sum equal to the overlap count.
3. The running sum changes only at those two points, so it stays constant between them.
4. Adding L and R + 1 to the coordinate set makes every window cover whole stretches.
5. A segment tree maximum over those stretches equals the best shooting moment.

| term | meaning |
|---|---|
| `eventCoords` | every start, end plus one, window start, and window end plus one |
| `eventDeltas` | change in overlap at one coordinate |
| `segmentTree` | maximum overlap over a range of stretches |

The coordinate list makes each window align with stored stretches.

The script example uses intervals [1,2], [2,3], [4,5], [6,7]. The sweep yields levels 1, 2, 1, 2, 1, 0, 1, 0 over the eight stretches from 1 to 7. Window [1,5] covers levels 1, 2, 1, 2, 1, so its maximum is 2. Window [5,7] covers 1, 0, 1, 0, so its maximum is 1.

The sample answers follow from the same four levels.

## Code

**Input and coordinate setup.** The reader loads animals and windows, then builds sorted coordinates.

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

The hand scanner skips arbitrary spacing.
All tokens here are positive, so no sign branch is needed.
Reading stdin once keeps the parse cost linear.

**Sweep and tree build.** Events turn coordinates into overlap levels, then a tree stores range maxima.

```nim
var eventDeltas = newSeq[int](uniqueCoords.len)
for animalIndex in 0 .. animalCount - 1:
  let startIndex = lowerBound(uniqueCoords, intervalStarts[animalIndex])
  let endIndex = lowerBound(uniqueCoords, intervalEnds[animalIndex] + 1)
  eventDeltas[startIndex] += 1
  eventDeltas[endIndex] -= 1

let segmentCount = uniqueCoords.len - 1
var treeBase = 1
while treeBase < segmentCount:
  treeBase = treeBase * 2
var segmentTree = newSeq[int](treeBase * 2)
var runningCoverage = 0
for segmentIndex in 0 .. segmentCount - 1:
  runningCoverage += eventDeltas[segmentIndex]
  segmentTree[treeBase + segmentIndex] = runningCoverage
```

Each animal contributes two events.
The running sum never needs a second pass over time.
Leaves hold one stretch each.

**Window answers.** Each query maps to a stretch interval and reads one tree maximum.

```nim
for queryIndex in 0 .. queryCount - 1:
  let leftSegment = lowerBound(uniqueCoords, queryLefts[queryIndex])
  let rightSegment = lowerBound(uniqueCoords, queryRights[queryIndex] + 1) - 1
  var bestCoverage = 0
  var treeLeft = treeBase + leftSegment
  var treeRight = treeBase + rightSegment
  while treeLeft <= treeRight:
    if (treeLeft mod 2) == 1:
      if segmentTree[treeLeft] > bestCoverage:
        bestCoverage = segmentTree[treeLeft]
      treeLeft += 1
    if (treeRight mod 2) == 0:
      if segmentTree[treeRight] > bestCoverage:
        bestCoverage = segmentTree[treeRight]
      treeRight -= 1
    treeLeft = treeLeft div 2
    treeRight = treeRight div 2
  appendOutput($bestCoverage)
  outputBuffer.add '\n'
```

Binary search finds both ends of the window.
The iterative tree walk avoids recursion.
Output is buffered and written in blocks.

## Complexity

The work splits into input, sorting, building, and answering.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | animal and window arrays |
| sort and sweep | sort coordinates, then one pass | coordinate and event arrays |
| tree build | one pass over stretches | two times the stretch count |
| queries | logarithmic maximum per window | none beyond the tree |

The sweep removes time values that cannot change the answer.

| measure | Big O |
|---|---|
| time | O((N + Q) log(N + Q)) |
| space | O(N + Q) |

Scanning every integer time for every query would cost far more than these logarithms. The indexed sweep answers all windows from one shared table.
