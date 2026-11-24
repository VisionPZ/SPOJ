{.passC: "-O3".}
{.optimization: speed.}
{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

import algorithm
import math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinityValue = 1e100
const equalFarSideEpsilon = 1e-11
const radiansPerMinute = 3.14159265358979323846 / 10800.0
const missingValue = -1000000000
const maximumCrossingTime = 10000

type RawPedestrian = tuple[bottom: int, angle: int]
type PlacedPedestrian = tuple[bottom: int, farSide: float]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9') and data[position] != '-':
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value * sign

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc compareFloat(left, right: float): int =
  if left < right: return -1
  if left > right: return 1
  return 0

proc comparePedestrian(left, right: PlacedPedestrian): int =
  if left.bottom < right.bottom: return -1
  if left.bottom > right.bottom: return 1
  return compareFloat(left.farSide, right.farSide)

proc lowerBound(values: seq[float], target: float): int =
  var lo = 0
  var hi = values.len
  while lo < hi:
    let mid = (lo + hi) div 2
    if values[mid] < target: lo = mid + 1
    else: hi = mid
  return lo

proc upperBound(values: seq[float], target: float): int =
  var lo = 0
  var hi = values.len
  while lo < hi:
    let mid = (lo + hi) div 2
    if values[mid] <= target: lo = mid + 1
    else: hi = mid
  return lo

var treeMax: seq[int] = @[]
var treeLazy: seq[int] = @[]
var treeSize = 0

proc applyTree(node, delta: int) =
  treeMax[node] += delta
  treeLazy[node] += delta

proc pushTree(node: int) =
  if treeLazy[node] != 0 and node < treeSize:
    applyTree(node * 2, treeLazy[node])
    applyTree(node * 2 + 1, treeLazy[node])
    treeLazy[node] = 0

proc addTree(node, low, high, fromIndex, toIndex, delta: int) =
  if fromIndex <= low and high <= toIndex:
    applyTree(node, delta)
    return
  pushTree(node)
  let middle = (low + high) div 2
  if fromIndex <= middle: addTree(node * 2, low, middle, fromIndex, toIndex, delta)
  if toIndex > middle: addTree(node * 2 + 1, middle + 1, high, fromIndex, toIndex, delta)
  treeMax[node] = max(treeMax[node * 2], treeMax[node * 2 + 1])

proc queryTree(node, low, high, fromIndex, toIndex: int): int =
  if fromIndex <= low and high <= toIndex: return treeMax[node]
  pushTree(node)
  let middle = (low + high) div 2
  var bestValue = missingValue
  if fromIndex <= middle: bestValue = max(bestValue, queryTree(node * 2, low, middle, fromIndex, toIndex))
  if toIndex > middle: bestValue = max(bestValue, queryTree(node * 2 + 1, middle + 1, high, fromIndex, toIndex))
  return bestValue

proc buildTree(values: seq[int], count: int) =
  treeSize = 1
  while treeSize < count: treeSize *= 2
  treeMax.setLen(treeSize * 2)
  treeLazy.setLen(treeSize * 2)
  for i in 0 ..< treeSize * 2: treeLazy[i] = 0
  for i in 0 ..< treeSize:
    if i < count: treeMax[treeSize + i] = values[i]
    else: treeMax[treeSize + i] = missingValue
  for i in countdown(treeSize - 1, 1):
    treeMax[i] = max(treeMax[i * 2], treeMax[i * 2 + 1])

proc solveGroup(width, maxSpeed, crossingTime: int, raws: seq[RawPedestrian]): int =
  let speedTime = int64(maxSpeed) * int64(crossingTime)
  if speedTime < int64(width): return 0
  let widthSquared = int64(width) * int64(width)
  let displacement = sqrt(float(speedTime * speedTime - widthSquared))
  var items: seq[PlacedPedestrian] = @[]
  for raw in raws:
    let farSide = float(raw.bottom) + tan(float(raw.angle) * radiansPerMinute) * float(width)
    items.add (raw.bottom, farSide)
  items.sort(comparePedestrian)
  var farSides: seq[float] = @[]
  for item in items: farSides.add item.farSide
  farSides.sort(compareFloat)

  # One point cell and one open interval cell per distinct far-side value.
  # Equal mathematical angles can differ by a few dozen ulps (e.g. tan(45deg)),
  # while genuinely different angles are at least 4e-10 apart, so a narrow
  # epsilon separates the two cases unambiguously.
  var distinctFars: seq[float] = @[]
  var ranks = newSeq[int](farSides.len)
  var rankCounter = -1
  for i in 0 ..< farSides.len:
    if i == 0 or farSides[i] > farSides[i - 1] + equalFarSideEpsilon:
      rankCounter += 1
      distinctFars.add farSides[i]
    ranks[i] = rankCounter
  let atomCount = distinctFars.len * 2 + 1
  var rankCounts = newSeq[int](distinctFars.len)
  for i in 0 ..< farSides.len:
    rankCounts[ranks[i]] += 1

  var atomLow = newSeq[float](atomCount)
  var atomHigh = newSeq[float](atomCount)
  var initial = newSeq[int](atomCount)
  atomLow[0] = -infinityValue
  atomHigh[0] = distinctFars[0]
  var running = 0
  for rank in 0 ..< distinctFars.len:
    running += rankCounts[rank]
    let pointIndex = rank * 2 + 1
    atomLow[pointIndex] = distinctFars[rank]
    atomHigh[pointIndex] = distinctFars[rank]
    initial[pointIndex] = running
    let intervalIndex = rank * 2 + 2
    atomLow[intervalIndex] = distinctFars[rank]
    if rank + 1 < distinctFars.len: atomHigh[intervalIndex] = distinctFars[rank + 1]
    else: atomHigh[intervalIndex] = infinityValue
    initial[intervalIndex] = running
  buildTree(initial, atomCount)

  var best = 0
  for k in 0 .. items.len:
    let gapLow = if k == 0: -infinityValue else: float(items[k - 1].bottom)
    let gapHigh = if k == items.len: infinityValue else: float(items[k].bottom)
    if k > 0 and k < items.len and gapLow == gapHigh:
      discard
    else:
      let lowBound = if k == 0: -infinityValue else: gapLow - displacement
      let highBound = if k == items.len: infinityValue else: gapHigh + displacement
      let firstIndex = upperBound(atomHigh, lowBound)
      var lastIndex = lowerBound(atomLow, highBound) - 1
      if lastIndex >= atomCount: lastIndex = atomCount - 1
      if firstIndex <= lastIndex:
        let value = queryTree(1, 0, treeSize - 1, firstIndex, lastIndex)
        if value > best: best = value
    if k < items.len:
      let rank = ranks[lowerBound(farSides, items[k].farSide)]
      addTree(1, 0, treeSize - 1, 0, rank * 2, 1)
      addTree(1, 0, treeSize - 1, rank * 2 + 2, atomCount - 1, -1)
  return best

var groups = newSeq[seq[RawPedestrian]](maximumCrossingTime + 1)

let caseCount = nextInt(inputData, scanPos)
for j in 0 ..< caseCount:
  let peopleCount = nextInt(inputData, scanPos)
  let streetWidth = nextInt(inputData, scanPos)
  let speedLimit = nextInt(inputData, scanPos)
  var usedTimes: seq[int] = @[]
  for k in 0 ..< peopleCount:
    let position = nextInt(inputData, scanPos)
    let crossing = nextInt(inputData, scanPos)
    let angle = nextInt(inputData, scanPos)
    if groups[crossing].len == 0: usedTimes.add crossing
    groups[crossing].add (position, angle)
  var best = 0
  for crossing in usedTimes:
    let value = solveGroup(streetWidth, speedLimit, crossing, groups[crossing])
    if value > best: best = value
  for crossing in usedTimes: groups[crossing].setLen 0
  appendOutput($(best))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
