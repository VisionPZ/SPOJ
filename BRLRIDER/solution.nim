import algorithm
import math

const flushBlockBytes = 1 shl 17
const fullCircle = 2 * PI

type AngularInterval = object
  startAngle: float
  endAngle: float

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  var numberSign = 1
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    if data[pos] == '-':
      numberSign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return numberSign * value

proc normalizedAngle(angle: float): float =
  var wrappedAngle = angle mod fullCircle
  if wrappedAngle < 0:
    wrappedAngle += fullCircle
  return wrappedAngle

proc compareIntervals(left, right: AngularInterval): int =
  if left.startAngle < right.startAngle:
    return -1
  if left.startAngle > right.startAngle:
    return 1
  if left.endAngle < right.endAngle:
    return -1
  if left.endAngle > right.endAngle:
    return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let obstacleCount = nextInt(inputData, scanPos)
var intervals = newSeq[AngularInterval]()
var fullyHidden = false
for obstacleIndex in 0 .. obstacleCount - 1:
  let centerX = nextInt(inputData, scanPos)
  let centerY = nextInt(inputData, scanPos)
  let radius = nextInt(inputData, scanPos)
  let distanceSquared = centerX * centerX + centerY * centerY
  let distance = sqrt(float(distanceSquared))
  if distance < float(radius):
    fullyHidden = true
    break
  let ratio = float(radius) / distance
  let halfAngle = arcsin(ratio)
  let middleAngle = arctan2(float(centerY), float(centerX))
  let leftAngle = normalizedAngle(middleAngle - halfAngle)
  let rightAngle = normalizedAngle(middleAngle + halfAngle)
  if leftAngle <= rightAngle:
    intervals.add(AngularInterval(startAngle: leftAngle, endAngle: rightAngle))
  else:
    intervals.add(AngularInterval(startAngle: 0.0, endAngle: rightAngle))
    intervals.add(AngularInterval(startAngle: leftAngle, endAngle: fullCircle))

if fullyHidden:
  appendOutput("100%\n")
else:
  intervals.sort(compareIntervals)
  var coveredAngle = 0.0
  if intervals.len > 0:
    var currentStart = intervals[0].startAngle
    var currentEnd = intervals[0].endAngle
    for intervalIndex in 1 .. intervals.len - 1:
      let interval = intervals[intervalIndex]
      if interval.startAngle <= currentEnd:
        if interval.endAngle > currentEnd:
          currentEnd = interval.endAngle
      else:
        coveredAngle += currentEnd - currentStart
        currentStart = interval.startAngle
        currentEnd = interval.endAngle
    coveredAngle += currentEnd - currentStart
  let percentage = int(coveredAngle / fullCircle * 100.0 + 0.5 + 1e-9)
  appendOutput($percentage & "%\n")
stdout.write outputBuffer
outputBuffer.setLen 0
