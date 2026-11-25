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

proc readAllInput() =
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

readAllInput()
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
