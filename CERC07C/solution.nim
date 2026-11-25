import algorithm
import math

const flushBlockBytes = 1 shl 17
const turn = 6.283185307179586476925

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSigned(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
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

type AngleEvent = tuple[angle: float64, kind: int]

proc compareEvents(left: AngleEvent, right: AngleEvent): int =
  if left.angle < right.angle:
    return -1
  if left.angle > right.angle:
    return 1
  if left.kind > right.kind:
    return -1
  if left.kind < right.kind:
    return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let pointCount = nextSigned(inputData, scanPos)
  let reach = nextSigned(inputData, scanPos)
  if pointCount == 0 and reach == 0:
    break
  var pointXs = newSeq[int](pointCount)
  var pointYs = newSeq[int](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    pointXs[pointIndex] = nextSigned(inputData, scanPos)
    pointYs[pointIndex] = nextSigned(inputData, scanPos)
  let effectiveRadius = float64(reach) + 0.0000001
  let reachLimit = 2.0 * effectiveRadius
  let reachLimitSquared = reachLimit * reachLimit
  var bestCoverage = 1
  for anchorIndex in 0 .. pointCount - 1:
    var events: seq[AngleEvent] = @[]
    for otherIndex in 0 .. pointCount - 1:
      if otherIndex == anchorIndex:
        continue
      let deltaX = float64(pointXs[otherIndex] - pointXs[anchorIndex])
      let deltaY = float64(pointYs[otherIndex] - pointYs[anchorIndex])
      let distanceSquared = deltaX * deltaX + deltaY * deltaY
      if distanceSquared > reachLimitSquared:
        continue
      let distance = sqrt(distanceSquared)
      var ratio = distance / reachLimit
      if ratio > 1.0:
        ratio = 1.0
      let spread = arccos(ratio)
      let direction = arctan2(deltaY, deltaX) + turn
      let leftAngle = direction - spread
      let rightAngle = direction + spread
      events.add (leftAngle, 1)
      events.add (rightAngle, 0)
      events.add (leftAngle + turn, 1)
      events.add (rightAngle + turn, 0)
    events.sort(compareEvents)
    var activeCoverage = 0
    var bestHere = 0
    for event in events:
      if event.kind == 1:
        activeCoverage += 1
        if activeCoverage > bestHere:
          bestHere = activeCoverage
      else:
        activeCoverage -= 1
    let totalCoverage = bestHere + 1
    if totalCoverage > bestCoverage:
      bestCoverage = totalCoverage
  appendOutput("It is possible to cover " & $bestCoverage & " points.")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
