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
const smallGroupLimit = 12
const radiansPerMinute = 3.14159265358979323846 / 10800.0
const missingValue = -1000000000
const maximumCrossingTime = 10000
const validEpsilon = 1e-7
const solveEpsilon = 1e-10

type RawPedestrian = tuple[bottom: int, angle: int]
type PlacedPedestrian = tuple[bottom: int, farSide: float]
type LinearRow = array[0 .. 4, float]

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

proc solveLinearSystem(rows: seq[LinearRow]): seq[float] =
  let variableCount = 4
  var matrix = newSeq[LinearRow](rows.len)
  for rowIndex in 0 ..< rows.len:
    matrix[rowIndex] = rows[rowIndex]
  for column in 0 ..< variableCount:
    var pivotRow = -1
    for rowIndex in column ..< matrix.len:
      if abs(matrix[rowIndex][column]) > solveEpsilon:
        pivotRow = rowIndex
        break
    if pivotRow == -1: return @[]
    let temporary = matrix[column]
    matrix[column] = matrix[pivotRow]
    matrix[pivotRow] = temporary
    let pivotValue = matrix[column][column]
    for index in 0 .. variableCount:
      matrix[column][index] = matrix[column][index] / pivotValue
    for rowIndex in 0 ..< matrix.len:
      if rowIndex != column:
        let factor = matrix[rowIndex][column]
        if abs(factor) > 1e-15:
          for index in 0 .. variableCount:
            matrix[rowIndex][index] = matrix[rowIndex][index] - factor * matrix[column][index]
  for rowIndex in variableCount ..< matrix.len:
    if abs(matrix[rowIndex][variableCount]) > 1e-5: return @[]
  var result = newSeq[float](variableCount)
  for index in 0 ..< variableCount: result[index] = matrix[index][variableCount]
  return result

proc pedestrianRow(bottom, crossing: int, farSide: float): LinearRow =
  var row: LinearRow
  row[0] = float(crossing)
  row[1] = float(bottom)
  row[2] = -farSide
  row[3] = 1.0
  row[4] = float(bottom) * float(crossing)
  return row

proc fixedRow(columnIndex: int, target: float): LinearRow =
  var row: LinearRow
  for index in 0 .. 4: row[index] = 0.0
  row[columnIndex] = 1.0
  row[4] = target
  return row

proc considerSolution(width, maxSpeed, count: int, bottoms: seq[int],
                      crossingTimes: seq[int], farSides: seq[float],
                      solution: seq[float], best: var int) =
  if solution.len != 4: return
  let startX = solution[0]
  let farTime = solution[1]
  let delay = solution[2]
  let combined = solution[3]
  if delay <= validEpsilon or delay > farTime + validEpsilon: return
  let farX = (combined + startX * farTime) / delay
  let duration = farTime - delay
  let horizontal = farX - startX
  if float(maxSpeed) * duration + validEpsilon < sqrt(float(width) * float(width) + horizontal * horizontal): return
  for index in 0 ..< count:
    if abs(startX - float(bottoms[index])) < 1e-6: return
  var hits = 0
  for index in 0 ..< count:
    let bottom = float(bottoms[index])
    let crossing = float(crossingTimes[index])
    let farSide = farSides[index]
    if crossing > duration + validEpsilon:
      if delay <= validEpsilon: continue
      let ratio = delay / (crossing - duration)
      if ratio > 1.0 + validEpsilon: continue
      if abs(startX + horizontal * ratio - (bottom + (farSide - bottom) * ratio)) < 1e-6:
        hits += 1
    elif crossing < duration - validEpsilon:
      continue
    else:
      if delay > validEpsilon: continue
      let denominator = horizontal - (farSide - bottom)
      if abs(denominator) < validEpsilon: continue
      let ratio = (bottom - startX) / denominator
      if ratio >= -validEpsilon and ratio <= 1.0 + validEpsilon and abs(startX - bottom) > validEpsilon:
        hits += 1
  if hits > best: best = hits

proc delayedSolve(width, maxSpeed: int, people: seq[(int, int, float)]): int =
  let count = people.len
  var bottoms = newSeq[int](count)
  var farSides = newSeq[float](count)
  var crossingTimes = newSeq[int](count)
  for index in 0 ..< count:
    bottoms[index] = people[index][0]
    crossingTimes[index] = people[index][1]
    farSides[index] = people[index][2]
  var rows = newSeq[LinearRow](count)
  for index in 0 ..< count:
    rows[index] = pedestrianRow(bottoms[index], crossingTimes[index], farSides[index])

  var aValues: seq[float] = @[0.0, 1.0, 2.0, 3.0]
  var bValues: seq[float] = @[]
  for index in 0 ..< count:
    let crossing = float(crossingTimes[index])
    aValues.add crossing
    aValues.add crossing / 2.0
    aValues.add crossing - 1.0
    bValues.add crossing
    bValues.add crossing - 1.0
    bValues.add crossing - 2.0
    bValues.add crossing - 3.0
    bValues.add crossing + 1.0
    bValues.add crossing / 2.0
  aValues.sort(compareFloat)
  bValues.sort(compareFloat)

  var best = 0

  for first in 0 ..< count:
    for second in first + 1 ..< count:
      for third in second + 1 ..< count:
        for fourth in third + 1 ..< count:
          var system: seq[LinearRow] = @[rows[first], rows[second], rows[third], rows[fourth]]
          considerSolution(width, maxSpeed, count, bottoms, crossingTimes, farSides,
                           solveLinearSystem(system), best)
  for first in 0 ..< count:
    for second in first + 1 ..< count:
      for third in second + 1 ..< count:
        var base: seq[LinearRow] = @[rows[first], rows[second], rows[third]]
        for value in aValues:
          var system = base
          system.add fixedRow(2, value)
          considerSolution(width, maxSpeed, count, bottoms, crossingTimes, farSides,
                           solveLinearSystem(system), best)
        for value in bValues:
          var system = base
          system.add fixedRow(1, value)
          considerSolution(width, maxSpeed, count, bottoms, crossingTimes, farSides,
                           solveLinearSystem(system), best)
  for first in 0 ..< count:
    for second in first + 1 ..< count:
      var base: seq[LinearRow] = @[rows[first], rows[second]]
      for delayValue in aValues:
        for farTimeValue in bValues:
          if farTimeValue <= delayValue: continue
          var system = base
          system.add fixedRow(2, delayValue)
          system.add fixedRow(1, farTimeValue)
          considerSolution(width, maxSpeed, count, bottoms, crossingTimes, farSides,
                           solveLinearSystem(system), best)
  return best

var groups = newSeq[seq[RawPedestrian]](maximumCrossingTime + 1)

let caseCount = nextInt(inputData, scanPos)
for j in 0 ..< caseCount:
  let peopleCount = nextInt(inputData, scanPos)
  let streetWidth = nextInt(inputData, scanPos)
  let speedLimit = nextInt(inputData, scanPos)
  var usedTimes: seq[int] = @[]
  var allPeople: seq[(int, int, float)] = @[]
  for k in 0 ..< peopleCount:
    let position = nextInt(inputData, scanPos)
    let crossing = nextInt(inputData, scanPos)
    let angle = nextInt(inputData, scanPos)
    if groups[crossing].len == 0: usedTimes.add crossing
    groups[crossing].add (position, angle)
    let farSide = float(position) + tan(float(angle) * radiansPerMinute) * float(streetWidth)
    allPeople.add (position, crossing, farSide)
  var best = 0
  for crossing in usedTimes:
    let value = solveGroup(streetWidth, speedLimit, crossing, groups[crossing])
    if value > best: best = value
  if peopleCount <= smallGroupLimit:
    let delayed = delayedSolve(streetWidth, speedLimit, allPeople)
    if delayed > best: best = delayed
  for crossing in usedTimes: groups[crossing].setLen 0
  appendOutput($(best))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
