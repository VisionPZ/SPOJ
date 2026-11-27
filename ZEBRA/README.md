# ZEBRA — The Zebra Crossing (SPOJ)
<https://www.spoj.com/problems/ZEBRA/>

## Problem

The input gives the start position, crossing time, and angle of each pedestrian across a street. You choose your own start, angle, and speed to maximize how many you collide with.

The input starts with the case count. Each case gives the person count, street width, and speed limit, then one start, crossing time, and angle per person. Print the maximum collisions.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Cases | at most 100 |
| People `n` | 1 to 10000 |
| Street width `w` | 1 to 100 meters |
| Speed limit `v` | 1 to 10000 m/s |
| Start coordinate | -10000 to 10000 |
| Crossing time | 1 to 10000 seconds |
| Angle | -5000 to 5000 units of 1/60 degree |
| Judge time | 17000 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

A crossing time equals the shared progress clock.

Sample input and output:

Input:

```
1
5 20 2
-20 10 2700
20 10 -2700
-5 1 4000
-4 1 4000
5 1 -4000
```

Output:

```
2
```

## Idea

Only people with your crossing time can collide. Think of picking a lane on a crosswalk and counting paths that cross your own.

The program groups people by crossing time. For each gap between start positions, it turns each person into an interval of far-side targets. A lazy segment tree (a range-update tree) finds the deepest overlap. Each group costs O(k log k) for k people. Comparing every pair would cost O(n^2).

Takeaway: shared crossing time reduces collisions to interval overlap.

## Why It Works

Equal heights force equal crossing times.

1. A person starting at `s` with angle `a` finishes at `q = s + w * tan(a)`.
2. Both walkers cover the same height fraction at a given time, so matching heights need matching crossing times.
3. The speed limit allows horizontal travel `D = sqrt((v * t)^2 - w^2)`.
4. For a waiting point between two starts, a person collides when the start gap and finish gap have opposite signs.
5. That test becomes one interval of far-side targets, clipped to `s - D` and `s + D`.

The terms are:

| Term | Meaning |
| --- | --- |
| `farCoord` | Far-side target coordinate of a walker |
| `displacement` | Maximum horizontal travel `D` |
| `gapIndex` | Waiting gap between two start positions |
| `atom` | One point or open interval of far-side values |
| `treeMax` | Largest interval overlap count |

`toleranceEps` keeps touching endpoints equal.

A script checked the sample case:

| Crossing time | Max travel | Displacement `D` | Far-side targets |
| --- | --- | --- | --- |
| 1 second | 2 meters | unreachable | none |
| 10 seconds | 20 meters | 0 meters | 0 and 0 |

Waiting at coordinate 0 hits both ten-second walkers at the far edge.

## Code

**Constants and input buffer.**

```nim
import algorithm, math

{.passC: "-O3".}
{.passL: "-s".}
{.push checks: off, assertions: off, stackTrace: off, lineDir: off.}

const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  missingValue = -1_000_000_000
  toleranceEps = 1e-10
  infinityValue = 1e30
  radiansPerMinute = PI / 10800.0
  minStartCoord = -10000
  maxStartCoord = 10000
  coordSpan = maxStartCoord - minStartCoord + 1
  unlimitedDispBound = 30000.0

var inputData = ""
```

Tangent uses radians per minute. The stamp array marks occupied start coordinates inside the legal range.

**Bulk input and output.**

```nim
proc readInputStream() =
  var chunk = newString(flushBlockBytes)
  var totalBytes = 0
  while true:
    let bytesRead = stdin.readBuffer(addr chunk[0], flushBlockBytes)
    if bytesRead <= 0:
      break
    let previousLen = totalBytes
    totalBytes += bytesRead
    if inputData.len < totalBytes:
      let nextCapacity = max(totalBytes, inputData.len * 2)
      inputData.setLen(nextCapacity)
    copyMem(addr inputData[previousLen], addr chunk[0], bytesRead)
  inputData.setLen(totalBytes)

var scanPos = 0

proc nextInt(): int {.inline.} =
  let dataLen = inputData.len
  while scanPos < dataLen and inputData[scanPos] != '-' and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    inc scanPos
  var signValue = 1
  if scanPos < dataLen and inputData[scanPos] == '-':
    signValue = -1
    inc scanPos
  var value = 0
  while scanPos < dataLen and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    inc scanPos
  return signValue * value

var outputBuffer = ""

proc appendInt(value: int) {.inline.} =
  outputBuffer.add($value)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)
```

A chunked reader and a hand scanner handle signed integers. Answers flush in blocks.

**Lazy segment tree.**

```nim
var treeMax: seq[int] = @[]
var treeLazy: seq[int] = @[]
var treeSize = 0

proc applyTree(node, delta: int) {.inline.} =
  treeMax[node] += delta
  treeLazy[node] += delta

proc pushTree(node: int) {.inline.} =
  let pending = treeLazy[node]
  if pending != 0 and node < treeSize:
    applyTree(node shl 1, pending)
    applyTree((node shl 1) or 1, pending)
    treeLazy[node] = 0

proc addTree(node, lowIdx, highIdx, queryLow, queryHigh, delta: int) =
  if queryLow <= lowIdx and highIdx <= queryHigh:
    applyTree(node, delta)
    return
  pushTree(node)
  let midIdx = (lowIdx + highIdx) shr 1
  if queryLow <= midIdx:
    addTree(node shl 1, lowIdx, midIdx, queryLow, queryHigh, delta)
  if queryHigh > midIdx:
    addTree((node shl 1) or 1, midIdx + 1, highIdx, queryLow, queryHigh, delta)
  treeMax[node] = max(treeMax[node shl 1], treeMax[(node shl 1) or 1])

proc queryTree(node, lowIdx, highIdx, queryLow, queryHigh: int): int =
  if queryLow <= lowIdx and highIdx <= queryHigh:
    return treeMax[node]
  pushTree(node)
  let midIdx = (lowIdx + highIdx) shr 1
  var bestValue = missingValue
  if queryLow <= midIdx:
    bestValue = max(bestValue, queryTree(node shl 1, lowIdx, midIdx, queryLow, queryHigh))
  if queryHigh > midIdx:
    bestValue = max(bestValue, queryTree((node shl 1) or 1, midIdx + 1, highIdx, queryLow, queryHigh))
  return bestValue

proc buildTree(values: seq[int], count: int) =
  treeSize = 1
  while treeSize < count: treeSize = treeSize shl 1
  treeMax.setLen(treeSize shl 1)
  treeLazy.setLen(treeSize shl 1)
  for i in 0..<(treeSize shl 1): treeLazy[i] = 0
  for i in 0..<treeSize:
    if i < count: treeMax[treeSize + i] = values[i]
    else: treeMax[treeSize + i] = missingValue
  for i in countdown(treeSize - 1, 1):
    treeMax[i] = max(treeMax[i shl 1], treeMax[(i shl 1) or 1])
```

`addTree` shifts whole covered ranges. `pushTree` passes pending shifts to children. `queryTree` returns the best overlap in a range.

**Walker types and helpers.**

```nim
type
  Pedestrian = object
    startCoord, crossingTime, angleMinutes: int
  PlacedPedestrian = object
    startCoord: int
    farCoord: float

proc compareFloat(left, right: float): int =
  if left < right: return -1
  if left > right: return 1
  return 0

proc comparePedestrianTime(left, right: Pedestrian): int =
  if left.crossingTime != right.crossingTime:
    return cmp(left.crossingTime, right.crossingTime)
  return cmp(left.startCoord, right.startCoord)

proc comparePlaced(left, right: PlacedPedestrian): int =
  if left.startCoord != right.startCoord:
    return cmp(left.startCoord, right.startCoord)
  return compareFloat(left.farCoord, right.farCoord)

proc lowerBoundFloat(values: seq[float], target: float): int {.inline.} =
  var lowIdx = 0
  var highIdx = values.len
  while lowIdx < highIdx:
    let midIdx = (lowIdx + highIdx) shr 1
    if values[midIdx] < target: lowIdx = midIdx + 1
    else: highIdx = midIdx
  return lowIdx

proc upperBoundFloat(values: seq[float], target: float): int {.inline.} =
  var lowIdx = 0
  var highIdx = values.len
  while lowIdx < highIdx:
    let midIdx = (lowIdx + highIdx) shr 1
    if values[midIdx] <= target: lowIdx = midIdx + 1
    else: highIdx = midIdx
  return lowIdx

proc exactTangent(angleMinutes: int): float {.inline.} =
  if angleMinutes == 0: return 0.0
  if angleMinutes == 2700: return 1.0
  if angleMinutes == -2700: return -1.0
  return tan(float(angleMinutes) * radiansPerMinute)

```

Comparators sort by time, start, and far coordinate. `exactTangent` avoids floating error at zero and right angles.

**Group solver.**

```nim
var occupiedStamp: array[coordSpan, int]
var currentCaseStamp = 0

proc isOccupiedCoord(coord: int): bool {.inline.} =
  if coord < minStartCoord or coord > maxStartCoord:
    return false
  return occupiedStamp[coord - minStartCoord] == currentCaseStamp

proc solveGroup(streetWidth, maxSpeed, crossingTime: int,
                pedestrians: seq[Pedestrian], groupStart, groupStop: int): int =
  let maxTravel = int64(maxSpeed) * int64(crossingTime)
  let width64 = int64(streetWidth)
  if maxTravel < width64: return 0
  let zeroDisplacement = (maxTravel == width64)
  let displacement =
    if zeroDisplacement: 0.0
    else: sqrt(float(maxTravel * maxTravel - width64 * width64))

  let groupCount = groupStop - groupStart
  var placed = newSeq[PlacedPedestrian](groupCount)
  var farCoords = newSeq[float](groupCount)
  let widthFloat = float(streetWidth)
  for i in 0..<groupCount:
    let person = pedestrians[groupStart + i]
    let farValue = float(person.startCoord) + exactTangent(person.angleMinutes) * widthFloat
    placed[i] = PlacedPedestrian(startCoord: person.startCoord, farCoord: farValue)
    farCoords[i] = farValue

  placed.sort(comparePlaced)
  farCoords.sort(compareFloat)

  var distinctFars: seq[float] = @[]
  var ranks = newSeq[int](groupCount)
  var rankCounts: seq[int] = @[]
  for i in 0..<groupCount:
    if i == 0 or farCoords[i] - distinctFars[distinctFars.len - 1] > toleranceEps:
      distinctFars.add(farCoords[i])
      rankCounts.add(1)
    else:
      inc rankCounts[rankCounts.len - 1]
    ranks[i] = distinctFars.len - 1

  let distinctCount = distinctFars.len
  let atomCount = distinctCount * 2 + 1
  var atomLow = newSeq[float](atomCount)
  var atomHigh = newSeq[float](atomCount)
  var initialCounts = newSeq[int](atomCount)

  atomLow[0] = -infinityValue
  atomHigh[0] = distinctFars[0]
  initialCounts[0] = 0
  var runningCount = 0
  for rank in 0..<distinctCount:
    runningCount += rankCounts[rank]
    let pointIndex = rank * 2 + 1
    atomLow[pointIndex] = distinctFars[rank]
    atomHigh[pointIndex] = distinctFars[rank]
    if zeroDisplacement and abs(distinctFars[rank]) < 1e9:
      let nearestInt = int(round(distinctFars[rank]))
      if abs(distinctFars[rank] - float(nearestInt)) <= toleranceEps and isOccupiedCoord(nearestInt):
        initialCounts[pointIndex] = missingValue
      else:
        initialCounts[pointIndex] = runningCount
    else:
      initialCounts[pointIndex] = runningCount

    let intervalIndex = rank * 2 + 2
    atomLow[intervalIndex] = distinctFars[rank]
    atomHigh[intervalIndex] = if rank + 1 < distinctCount: distinctFars[rank + 1] else: infinityValue
    initialCounts[intervalIndex] = runningCount

  buildTree(initialCounts, atomCount)

  let unlimitedReach = displacement > unlimitedDispBound
  var bestCollisions = 0
  for gapIndex in 0..groupCount:
    if gapIndex == 0 or gapIndex == groupCount or placed[gapIndex - 1].startCoord != placed[gapIndex].startCoord:
      let firstAtom =
        if gapIndex == 0 or unlimitedReach: 0
        else: upperBoundFloat(atomHigh, float(placed[gapIndex - 1].startCoord) - displacement + toleranceEps)
      var lastAtom =
        if gapIndex == groupCount or unlimitedReach: atomCount - 1
        else: lowerBoundFloat(atomLow, float(placed[gapIndex].startCoord) + displacement - toleranceEps) - 1
      if lastAtom >= atomCount: lastAtom = atomCount - 1
      if firstAtom <= lastAtom:
        let candidate = queryTree(1, 0, treeSize - 1, firstAtom, lastAtom)
        if candidate > bestCollisions: bestCollisions = candidate
    if gapIndex < groupCount:
      let rank = ranks[lowerBoundFloat(farCoords, placed[gapIndex].farCoord)]
      addTree(1, 0, treeSize - 1, 0, rank * 2, 1)
      addTree(1, 0, treeSize - 1, rank * 2 + 2, atomCount - 1, -1)
  return bestCollisions
```

Distinct far values become tree atoms. Each gap updates two ranges, then queries the best overlap. The tree resets through its build step.

**Case driver.**

```nim
readInputStream()
let caseCount = nextInt()
for _ in 0..<caseCount:
  let peopleCount = nextInt()
  let streetWidth = nextInt()
  let maxSpeed = nextInt()
  inc currentCaseStamp
  var pedestrians = newSeq[Pedestrian](peopleCount)
  for i in 0..<peopleCount:
    let startCoord = nextInt()
    let crossingTime = nextInt()
    let angleMinutes = nextInt()
    pedestrians[i] = Pedestrian(startCoord: startCoord, crossingTime: crossingTime, angleMinutes: angleMinutes)
    if startCoord >= minStartCoord and startCoord <= maxStartCoord:
      occupiedStamp[startCoord - minStartCoord] = currentCaseStamp
  pedestrians.sort(comparePedestrianTime)
  var bestCollisions = 0
  var groupStart = 0
  while groupStart < peopleCount:
    var groupStop = groupStart + 1
    while groupStop < peopleCount and pedestrians[groupStop].crossingTime == pedestrians[groupStart].crossingTime:
      inc groupStop
    let groupBest = solveGroup(streetWidth, maxSpeed, pedestrians[groupStart].crossingTime,
                               pedestrians, groupStart, groupStop)
    if groupBest > bestCollisions: bestCollisions = groupBest
    groupStart = groupStop
  appendInt(bestCollisions)

if outputBuffer.len > 0:
  stdout.write(outputBuffer)
  outputBuffer.setLen(0)
```

People sort by crossing time, then split into equal-time groups. The largest group result becomes the answer.

## Complexity

Sorting and tree updates dominate.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total numbers) | O(Input size) |
| Sort by time | O(n log n) | O(n) |
| Group solve | O(n log n) total | O(n) |
| Output | O(T) | O(1) |

Group sizes add to n across one case.

| Measure | Bound |
| --- | --- |
| Time | O(n log n) per case |
| Space | O(n) per case |

Ten thousand people stay inside the time limit.

Testing every walker pair would cost a hundred million checks.
