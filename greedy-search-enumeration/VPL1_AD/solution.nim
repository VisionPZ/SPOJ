import math

const flushBlockBytes = 1 shl 17
const unreachableDistance = 1e100
const tieTolerance = 1e-8

type GridPoint = tuple[x: int, y: int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negativeValue = false
  if pos < data.len and data[pos] == '-':
    negativeValue = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negativeValue:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc turnValue(first: GridPoint, second: GridPoint, third: GridPoint): int64 =
  return int64(second.x - first.x) * int64(third.y - first.y) -
         int64(second.y - first.y) * int64(third.x - first.x)

proc onSegment(first: GridPoint, second: GridPoint, point: GridPoint): bool =
  return point.x >= min(first.x, second.x) and point.x <= max(first.x, second.x) and
         point.y >= min(first.y, second.y) and point.y <= max(first.y, second.y)

proc segmentsCross(firstA: GridPoint, firstB: GridPoint,
                   secondA: GridPoint, secondB: GridPoint): bool =
  let firstTurnA = turnValue(firstA, firstB, secondA)
  let firstTurnB = turnValue(firstA, firstB, secondB)
  let secondTurnA = turnValue(secondA, secondB, firstA)
  let secondTurnB = turnValue(secondA, secondB, firstB)
  if ((firstTurnA > 0 and firstTurnB < 0) or
      (firstTurnA < 0 and firstTurnB > 0)) and
     ((secondTurnA > 0 and secondTurnB < 0) or
      (secondTurnA < 0 and secondTurnB > 0)):
    return true
  if firstTurnA == 0 and onSegment(firstA, firstB, secondA):
    return true
  if firstTurnB == 0 and onSegment(firstA, firstB, secondB):
    return true
  if secondTurnA == 0 and onSegment(secondA, secondB, firstA):
    return true
  if secondTurnB == 0 and onSegment(secondA, secondB, firstB):
    return true
  return false

proc pointDistance(first: GridPoint, second: GridPoint): float =
  let deltaX = float(second.x - first.x)
  let deltaY = float(second.y - first.y)
  return sqrt(deltaX * deltaX + deltaY * deltaY)

proc appendFraction(thousandths: int64) =
  if thousandths < 100:
    appendOutput("0")
  if thousandths < 10:
    appendOutput("0")
  appendOutput($thousandths)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let leafCount = nextInt(inputData, scanPos)
  let stickCount = nextInt(inputData, scanPos)
  let jumpLimit = nextInt(inputData, scanPos)
  var gardenPoints = newSeq[GridPoint](leafCount + 1)
  gardenPoints[0] = (x: 0, y: 0)
  for leafIndex in 1 .. leafCount:
    let pointX = nextInt(inputData, scanPos)
    let pointY = nextInt(inputData, scanPos)
    gardenPoints[leafIndex] = (x: pointX, y: pointY)
  var stickStarts = newSeq[GridPoint](stickCount)
  var stickEnds = newSeq[GridPoint](stickCount)
  for stickIndex in 0 .. stickCount - 1:
    let startX = nextInt(inputData, scanPos)
    let startY = nextInt(inputData, scanPos)
    let endX = nextInt(inputData, scanPos)
    let endY = nextInt(inputData, scanPos)
    stickStarts[stickIndex] = (x: startX, y: startY)
    stickEnds[stickIndex] = (x: endX, y: endY)
  var distances = newSeq[seq[float]](leafCount + 1)
  var crossings = newSeq[seq[int]](leafCount + 1)
  for firstPoint in 0 .. leafCount:
    distances[firstPoint] = newSeq[float](leafCount + 1)
    crossings[firstPoint] = newSeq[int](leafCount + 1)
    for secondPoint in 0 .. leafCount:
      distances[firstPoint][secondPoint] = pointDistance(gardenPoints[firstPoint],
                                                        gardenPoints[secondPoint])
      var crossedSticks = 0
      for stickIndex in 0 .. stickCount - 1:
        if segmentsCross(gardenPoints[firstPoint], gardenPoints[secondPoint],
                         stickStarts[stickIndex], stickEnds[stickIndex]):
          crossedSticks += 1
      crossings[firstPoint][secondPoint] = crossedSticks
  let fullMask = (1 shl leafCount) - 1
  let jumpWidth = jumpLimit + 1
  let stateStride = leafCount * jumpWidth
  let stateCount = (fullMask + 1) * stateStride
  var suffixBest = newSeq[float](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    suffixBest[stateIndex] = unreachableDistance
  for lastLeaf in 0 .. leafCount - 1:
    for jumpCount in 0 .. jumpLimit:
      let completeIndex = fullMask * stateStride + lastLeaf * jumpWidth + jumpCount
      suffixBest[completeIndex] = 0.0
  for mask in countdown(fullMask - 1, 0):
    for lastLeaf in 0 .. leafCount - 1:
      for jumpCount in 0 .. jumpLimit:
        var bestDistance = unreachableDistance
        for nextLeaf in 0 .. leafCount - 1:
          if (mask and (1 shl nextLeaf)) != 0:
            continue
          let nextJumps = jumpCount + crossings[lastLeaf + 1][nextLeaf + 1]
          if nextJumps > jumpLimit:
            continue
          let nextMask = mask or (1 shl nextLeaf)
          let nextIndex = nextMask * stateStride + nextLeaf * jumpWidth + nextJumps
          let candidate = distances[lastLeaf + 1][nextLeaf + 1] + suffixBest[nextIndex]
          if candidate < bestDistance:
            bestDistance = candidate
        let currentIndex = mask * stateStride + lastLeaf * jumpWidth + jumpCount
        suffixBest[currentIndex] = bestDistance
  var optimalDistance = unreachableDistance
  for firstLeaf in 0 .. leafCount - 1:
    let firstJumps = crossings[0][firstLeaf + 1]
    if firstJumps > jumpLimit:
      continue
    let firstIndex = (1 shl firstLeaf) * stateStride + firstLeaf * jumpWidth + firstJumps
    let candidate = distances[0][firstLeaf + 1] + suffixBest[firstIndex]
    if candidate < optimalDistance:
      optimalDistance = candidate
  appendOutput("Scenario #" & $(caseIndex + 1) & ": ")
  if optimalDistance >= unreachableDistance / 2:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue
  let thousandths = int64(optimalDistance * 1000.0 + 0.5)
  appendOutput($int(thousandths div 1000))
  appendOutput(".")
  appendFraction(thousandths mod 1000)
  outputBuffer.add '\n'
  var pathLeaves = newSeq[int]()
  pathLeaves.add 0
  var currentMask = 0
  var currentPoint = 0
  var usedJumps = 0
  var walkedDistance = 0.0
  while currentMask != fullMask:
    var chosenLeaf = -1
    var chosenJumps = 0
    var chosenDistance = 0.0
    for nextLeaf in 0 .. leafCount - 1:
      if (currentMask and (1 shl nextLeaf)) != 0:
        continue
      let nextJumps = usedJumps + crossings[currentPoint][nextLeaf + 1]
      if nextJumps > jumpLimit:
        continue
      let nextMask = currentMask or (1 shl nextLeaf)
      let nextIndex = nextMask * stateStride + nextLeaf * jumpWidth + nextJumps
      let candidate = walkedDistance + distances[currentPoint][nextLeaf + 1] +
                      suffixBest[nextIndex]
      if abs(candidate - optimalDistance) < tieTolerance:
        chosenLeaf = nextLeaf
        chosenJumps = nextJumps
        chosenDistance = distances[currentPoint][nextLeaf + 1]
        break
    if chosenLeaf == -1:
      break
    walkedDistance += chosenDistance
    currentMask = currentMask or (1 shl chosenLeaf)
    currentPoint = chosenLeaf + 1
    usedJumps = chosenJumps
    pathLeaves.add chosenLeaf + 1
  for pathIndex in 0 .. pathLeaves.len - 1:
    if pathIndex > 0:
      outputBuffer.add ' '
    appendOutput($pathLeaves[pathIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
