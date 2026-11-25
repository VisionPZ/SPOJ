import algorithm
import math

const flushBlockBytes = 1 shl 17
const scaleFactor = 100
const fullTurn = 2.0 * PI
const angleTolerance = 1.0e-12

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

proc nextScaled(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var wholePart = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + int(data[pos]) - 48
    pos += 1
  var fractionPart = 0
  var fractionDigits = 0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and fractionDigits < 2 and data[pos] >= '0' and data[pos] <= '9':
      fractionPart = fractionPart * 10 + int(data[pos]) - 48
      fractionDigits += 1
      pos += 1
  while fractionDigits < 2:
    fractionPart = fractionPart * 10
    fractionDigits += 1
  let scaledValue = wholePart * scaleFactor + fractionPart
  if negative:
    return -scaledValue
  return scaledValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type SweepEvent = tuple[angle: float, delta: int]

proc compareEvents(left: SweepEvent, right: SweepEvent): int =
  if left.angle < right.angle:
    return -1
  elif left.angle > right.angle:
    return 1
  return 0

proc addAngleInterval(startAngle: float, endAngle: float,
                      events: var seq[SweepEvent], fullCount: var int) =
  var startNormalized = startAngle mod fullTurn
  var endNormalized = endAngle mod fullTurn
  if startNormalized < 0:
    startNormalized = startNormalized + fullTurn
  if endNormalized < 0:
    endNormalized = endNormalized + fullTurn
  if startNormalized < endNormalized:
    events.add((startNormalized, 1))
    events.add((endNormalized, -1))
  elif startNormalized > endNormalized:
    events.add((0.0, 1))
    events.add((endNormalized, -1))
    events.add((startNormalized, 1))
    events.add((fullTurn, -1))
  else:
    fullCount += 1

proc bestAtFlash(activeCircles: seq[int], circleXs: seq[int],
                 circleYs: seq[int], circleRs: seq[int]): int =
  let circleCount = activeCircles.len
  if circleCount == 0:
    return 0
  var bestTotal = 1
  for centerIndex in 0 .. circleCount - 1:
    let centerCircle = activeCircles[centerIndex]
    let centerX = float(circleXs[centerCircle])
    let centerY = float(circleYs[centerCircle])
    let centerRadius = float(circleRs[centerCircle])
    var events = newSeq[SweepEvent]()
    var fullCount = 0
    for otherIndex in 0 .. circleCount - 1:
      if otherIndex == centerIndex:
        continue
      let otherCircle = activeCircles[otherIndex]
      let deltaX = float(circleXs[otherCircle]) - centerX
      let deltaY = float(circleYs[otherCircle]) - centerY
      let centerDistance = sqrt(deltaX * deltaX + deltaY * deltaY)
      let otherRadius = float(circleRs[otherCircle])
      if centerDistance < angleTolerance:
        if otherRadius > centerRadius:
          fullCount += 1
        continue
      let lowRatio = (centerRadius - otherRadius) / centerDistance
      let highRatio = (centerRadius + otherRadius) / centerDistance
      if lowRatio > 1.0 + angleTolerance:
        continue
      if highRatio > 1.0 + angleTolerance:
        fullCount += 1
        continue
      let directionAngle = arctan2(deltaY, deltaX)
      let lowAngle = arccos(max(-1.0, min(1.0, lowRatio)))
      let highAngle = arccos(max(-1.0, min(1.0, highRatio)))
      addAngleInterval(directionAngle + highAngle, directionAngle + lowAngle, events, fullCount)
      addAngleInterval(directionAngle + fullTurn - lowAngle,
                       directionAngle + fullTurn - highAngle, events, fullCount)
    sort(events, compareEvents)
    var depth = fullCount
    var localBest = depth
    var eventIndex = 0
    while eventIndex < events.len:
      let eventAngle = events[eventIndex].angle
      while eventIndex < events.len and events[eventIndex].angle == eventAngle:
        depth = depth + events[eventIndex].delta
        eventIndex += 1
      if depth > localBest:
        localBest = depth
    let candidate = localBest + 1
    if candidate > bestTotal:
      bestTotal = candidate
  return bestTotal

let eventCount = nextInt(inputData, scanPos)
var circleXs = newSeq[int]()
var circleYs = newSeq[int]()
var circleRs = newSeq[int]()
var activeFlags = newSeq[bool]()
for eventIndex in 0 .. eventCount - 1:
  let eventKind = nextInt(inputData, scanPos)
  if eventKind == 1:
    circleXs.add(nextScaled(inputData, scanPos))
    circleYs.add(nextScaled(inputData, scanPos))
    circleRs.add(nextScaled(inputData, scanPos))
    activeFlags.add(true)
  elif eventKind == 2:
    let circleIndex = nextInt(inputData, scanPos) - 1
    activeFlags[circleIndex] = false
  else:
    var activeCircles = newSeq[int]()
    for circleIndex in 0 .. activeFlags.len - 1:
      if activeFlags[circleIndex]:
        activeCircles.add(circleIndex)
    appendOutput($bestAtFlash(activeCircles, circleXs, circleYs, circleRs))
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
