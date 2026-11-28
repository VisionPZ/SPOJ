# ADAKOHL — Ada and Kohlrabi (SPOJ)

<https://www.spoj.com/problems/ADAKOHL/>

## Problem

Each kohlrabi has coordinates and a quality that may be negative. Pick one straight line and add the qualities of every kohlrabi on it. Report the largest possible sum, where an empty line scores zero.

Input begins with T test cases. Each case gives N, then N lines with x, y and quality. No two kohlrabi share a coordinate. Output one line per case with the best sum.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| kohlrabi N | 1 to 3000 per case |
| coordinates x, y | -1000000000 to 1000000000 |
| quality q | -10000 to 10000 |
| judge limit | 4000 ms, 1536 MB |

The point count drives the design: checking all triples would need 2.7e10 tests for one large case.

Verbatim sample input:

```
5
4
0 0 1
1 1 1
2 2 1
3 3 1
5
0 0 -10
1 0 2
0 1 3
-1 0 2
0 -1 3
3
0 0 -1
1 1 -2
1 3 -5
2
0 0 666
1 7 -666
5
0 0 1
99999999 0 6
0 99999999 5
-99999999 0 6
0 -99999999 5
```

Verbatim sample output:

```
4
5
0
666
13
```

## Idea

Every line passes through at least one kohlrabi, so pick that one as an anchor, like choosing a hub before grouping spokes. From the hub, reduce each direction to a primitive integer vector; all points with the same vector lie on the same line. Sum qualities per direction and keep the largest total.

A hash table groups directions in O(1) expected time, so one anchor costs O(N) and a case costs O(N^2). Testing every pair of points against every third point costs O(N^3), which is too slow. Takeaway: group by normalized slope around each anchor.

## Why It Works

1. A line through an anchor is fully described by one direction vector, up to sign.
2. Divide each coordinate difference by the gcd of its absolute parts to get a primitive vector.
3. Flip the vector when its first nonzero part is negative, so opposite sides share one key.
4. Two points through the same anchor are collinear exactly when their primitive vectors match.
5. Summing the qualities of one group plus the anchor gives the line total for that anchor.
6. Every nonempty line has at least one kohlrabi, so some anchor covers it; starting the answer at zero also allows the empty line.

The main terms and formulas:

| term | meaning |
|---|---|
| `deltaX`, `deltaY` | coordinate difference from anchor to another point |
| `packSlope` | packs the primitive direction into one 64-bit key |
| `hashStamp` | marks slots used for the current anchor |
| `hashSum` | quality total for one direction |
| `touchedSlots` | slot list that avoids scanning the whole table |

The stamp avoids clearing a 32768-slot table for every anchor.

A script-generated trace for the second sample case, anchored at (0, 1) with quality 3:

```
direction (0, 1): points (0, 0) and (0, -1), sum -10 + 3 = -7, line total -4
direction (1, -1): point (1, 0), sum 2, line total 5
direction (1, 1): point (-1, 0), sum 2, line total 5
best over all anchors: 5
```

The trace matches the sample output 5.

All direction arithmetic is integer, so no rounding affects the grouping. Coordinate differences fit in int64, and packed keys use unsigned 64-bit values.

## Code

**Input and scanner.** The reader loads stdin once and handles negative coordinates and qualities.

```nim
const flushBlockBytes = 1 shl 17
const coordinateOffset: int64 = 2147483648
const hashMultiplier: uint64 = 1099511628211'u64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value
```

The skip loop stops at a minus sign, so negative values keep their sign.
Output is buffered, as shown next.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One final write flushes the answer lines after all cases.

**Greatest common divisor.** Primitive directions come from dividing by this value.

```nim
proc gcdAbs(firstValue: int64, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  if leftValue < 0:
    leftValue = -leftValue
  if rightValue < 0:
    rightValue = -rightValue
  while rightValue != 0:
    var remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue
```

Absolute values keep the result positive.
Distinct coordinates guarantee the divisor is nonzero.

**Direction hash table.** Each slot stores one packed slope and its summed quality.

```nim
var pointX = newSeq[int64](0)
var pointY = newSeq[int64](0)
var pointQuality = newSeq[int64](0)
var hashStamp = newSeq[int](0)
var hashKey = newSeq[uint64](0)
var hashSum = newSeq[int64](0)
var touchedSlots = newSeq[int](0)
var tableMask = 0
var currentStamp = 0

proc packSlope(deltaX: int64, deltaY: int64): uint64 =
  return (uint64(deltaX + coordinateOffset) shl 32) or uint64(deltaY + coordinateOffset)

proc addSlope(packedKey: uint64, quality: int64) =
  var slot = int((packedKey * hashMultiplier) and uint64(tableMask))
  while hashStamp[slot] == currentStamp and hashKey[slot] != packedKey:
    slot = (slot + 1) and tableMask
  if hashStamp[slot] != currentStamp:
    hashStamp[slot] = currentStamp
    hashKey[slot] = packedKey
    hashSum[slot] = quality
    touchedSlots.add slot
  else:
    hashSum[slot] = hashSum[slot] + quality
```

`coordinateOffset` shifts signed parts into the unsigned range before packing.
Linear probing stays short because the table holds at least eight slots per point.

**Driver.** Each anchor normalizes directions, then reads only its touched slots.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let pointCount = nextInt(inputData, scanPos)
  pointX.setLen pointCount
  pointY.setLen pointCount
  pointQuality.setLen pointCount
  for pointIndex in 0 .. pointCount - 1:
    pointX[pointIndex] = int64(nextInt(inputData, scanPos))
    pointY[pointIndex] = int64(nextInt(inputData, scanPos))
    pointQuality[pointIndex] = int64(nextInt(inputData, scanPos))
  var tableSize = 8
  while tableSize < pointCount * 8:
    tableSize = tableSize * 2
  tableMask = tableSize - 1
  hashStamp = newSeq[int](tableSize)
  hashKey = newSeq[uint64](tableSize)
  hashSum = newSeq[int64](tableSize)
  var bestSum: int64 = 0
  for anchorIndex in 0 .. pointCount - 1:
    currentStamp += 1
    touchedSlots.setLen 0
    if pointQuality[anchorIndex] > bestSum:
      bestSum = pointQuality[anchorIndex]
    for otherIndex in 0 .. pointCount - 1:
      if otherIndex != anchorIndex:
        var deltaX = pointX[otherIndex] - pointX[anchorIndex]
        var deltaY = pointY[otherIndex] - pointY[anchorIndex]
        let divisor = gcdAbs(deltaX, deltaY)
        deltaX = deltaX div divisor
        deltaY = deltaY div divisor
        if deltaX < 0 or (deltaX == 0 and deltaY < 0):
          deltaX = -deltaX
          deltaY = -deltaY
        addSlope(packSlope(deltaX, deltaY), pointQuality[otherIndex])
    for slot in touchedSlots:
      let candidate = pointQuality[anchorIndex] + hashSum[slot]
      if candidate > bestSum:
        bestSum = candidate
  appendOutput($bestSum)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sign rule puts opposite sides of a line in the same group.
The initial best of zero lets an all-negative case answer zero.

## Complexity

One hash insertion per ordered pair dominates the work.

| phase | time | space |
|---|---|---|
| input read | one pass over N triples | three point arrays |
| direction grouping | N anchors times N points | hash table of 8N slots |
| group sweep | one pass over touched slots per anchor | touched slot list |
| output | one buffered line per case | block buffer |

Grouping dominates because each ordered pair needs one gcd and one hash step.

| measure | Big O |
|---|---|
| time per case | O(N^2) expected |
| space per case | O(N) |

Checking every point pair against every third point costs O(N^3), which is far slower. Takeaway: normalize a direction once per pair, then group by it.
