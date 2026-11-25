# PLONK — Where to Drink the Plonk? (SPOJ)
<https://www.spoj.com/problems/PLONK/>

## Problem

A group of friends lives at crossroads of a square street grid. They want to meet at one friend's house and minimize the total walking distance.

Everyone walks along the streets and turns only at crossroads. Adjacent crossroads are one unit apart. Find the smallest total distance over all friends' houses.

Input: the first integer is t, the number of cases. Each case gives n friends, then n pairs of coordinates. Output: one integer per case, the minimum total distance.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases t | from the input |
| Friends n | 1 to 10000 |
| Coordinates | 0 to 100000 |
| Time limit | 6000 ms |
| Memory limit | 1536 MB |

The sample has seven friends:

```
1
7
1 3
3 2
3 5
6 9
10 1
12 4
5 7
```

```
39
```

Friend (3, 5) gives the smallest total of 39.

## Idea

Split the walk into horizontal and vertical parts, then pick the middle house on each axis. Picture friends living along one long road: the house that minimizes everyone's walking is the median one.

Street distance is Manhattan distance, |x₁ − x₂| + |y₁ − y₂|, so the two axes work independently. For a sorted list of coordinates, the sum of absolute differences is smallest at a median.

The meeting point must be a friend's house, so the program evaluates the cost at every friend coordinate. Prefix sums give each cost in O(1) after sorting. It keeps the lowest x-cost plus y-cost over all friends.

Sorting costs O(n log n) per case; the rest is O(n). Trying every pair of houses costs O(n²).

Takeaway: two median scans replace a grid search with a sort plus two linear passes.

## Why It Works

Four facts prove the method.

1. Manhattan distance separates into |x₁ − x₂| plus |y₁ − y₂|. The x-coordinate of the meeting house affects only the first term.
2. The sum of absolute deviations from a point is minimized at a median. With an even count, any point between the two middle values works, and one of the friend coordinates lies in that range.
3. For sorted coordinates and a value v at positions l through j, the left contribution is v × l − prefixX[l]. The right contribution is totalX − prefixX[j] − v × (n − j). Grouping equal values yields the exact cost.
4. Evaluating `costAtX[x] + costAtY[y]` over every friend checks all legal meeting houses, so the minimum is the answer.

These are the arrays in the computation:

| Term | Meaning |
| --- | --- |
| `coordX`, `coordY` | original coordinates of the friends |
| `sortedX`, `sortedY` | sorted copies used for prefix sums |
| `prefixX`, `prefixY` | running sums of the sorted values |
| `totalX`, `totalY` | sums of all coordinates |
| `costAtX[v]`, `costAtY[v]` | total axis distance if the meeting coordinate is v |

A script prints the total distance for each candidate friend in the sample:

```
| Friend | x cost | y cost | total |
| --- | --- | --- | --- |
| (1, 3) | 33 | 16 | 49 |
| (3, 2) | 23 | 19 | 42 |
| (3, 5) | 23 | 16 | 39 |
| (6, 9) | 22 | 32 | 54 |
| (10, 1) | 34 | 24 | 58 |
| (12, 4) | 44 | 15 | 59 |
| (5, 7) | 21 | 22 | 43 |
```

Friend (3, 5) has the smallest total, 39. The x-cost column is minimized near the median x of 5, and the y-cost near the median y of 4.

## Code

**Input.** One buffer holds the stream, and a small scanner reads integers.

```nim
{.push checks: off.}

import algorithm

const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  maxCoordValue = 100000

proc compareInts(left, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

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

`compareInts` gives the sort a stable ordering with no closure allocation. The scanner walks one shared buffer. Cost is one pass over the input bytes.

**Output.** Answers collect in a block-flushed buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush triggers every `flushBlockBytes` bytes. No write happens inside the friend loop. The cost is one pass over the answer text.

**Driver.** Each case sorts both axes, then scores every friend.

```nim
var costAtX: array[0..maxCoordValue, int64]
var costAtY: array[0..maxCoordValue, int64]

let caseCount = nextInt(inputData, scanPos)
for k in 0..<caseCount:
  let friendCount = nextInt(inputData, scanPos)
  var coordX: seq[int] = @[]
  var coordY: seq[int] = @[]
  coordX.setLen(friendCount)
  coordY.setLen(friendCount)
  var totalX = 0'i64
  var totalY = 0'i64
  for i in 0..<friendCount:
    let x = nextInt(inputData, scanPos)
    let y = nextInt(inputData, scanPos)
    coordX[i] = x
    coordY[i] = y
    totalX += x
    totalY += y

  var sortedX = coordX
  var sortedY = coordY
  sortedX.sort(compareInts)
  sortedY.sort(compareInts)

  var prefixX: seq[int64] = @[]
  var prefixY: seq[int64] = @[]
  prefixX.setLen(friendCount + 1)
  prefixY.setLen(friendCount + 1)
  for i in 0..<friendCount:
    prefixX[i + 1] = prefixX[i] + sortedX[i]
    prefixY[i + 1] = prefixY[i] + sortedY[i]

  var l = 0
  while l < friendCount:
    var j = l + 1
    while j < friendCount and sortedX[j] == sortedX[l]:
      j += 1
    let value = sortedX[l]
    costAtX[value] = int64(value) * l - prefixX[l] + (totalX - prefixX[j]) - int64(value) * (friendCount - j)
    l = j

  l = 0
  while l < friendCount:
    var j = l + 1
    while j < friendCount and sortedY[j] == sortedY[l]:
      j += 1
    let value = sortedY[l]
    costAtY[value] = int64(value) * l - prefixY[l] + (totalY - prefixY[j]) - int64(value) * (friendCount - j)
    l = j

  var minTotal = high(int64)
  for i in 0..<friendCount:
    let candidateTotal = costAtX[coordX[i]] + costAtY[coordY[i]]
    if candidateTotal < minTotal:
      minTotal = candidateTotal

  appendOutput($minTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The two `while l < friendCount` loops group equal coordinates, so a shared value gets one cost. `prefixX[j]` excludes the group starting at j, which forms the right-hand sum. Only friend coordinates are read back, so stale entries for unused values never matter.

## Complexity

Sorting and two linear scoring passes carry the work.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Sort both axes | O(n log n) | O(n) |
| Prefix sums | O(n) | O(n) |
| Cost tables | O(n) | O(maxCoordValue) |
| Best-friend scan | O(n) | O(1) |
| Output | O(cases) | O(block size) |

Sorting dominates, with O(n log n) time and O(n) extra space per case.

| Measure | Big O |
| --- | --- |
| Time per case | O(n log n) |
| Total time | O(sum of n log n over cases) |
| Working space | O(n + maxCoordValue) |

Testing every grid crossroad costs O(100000²) per case, far more than two median passes.
