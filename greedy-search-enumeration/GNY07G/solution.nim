import math

const flushBlockBytes = 1 shl 17
const angleEpsilon = 0.01

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

proc nextFloat(data: string, pos: var int): float =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '.':
    pos += 1
  var value = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10.0 + float(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var place = 0.1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      value = value + float(int(data[pos]) - 48) * place
      place = place * 0.1
      pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
let baselineSpan = nextFloat(inputData, scanPos)
let platformOffset = nextFloat(inputData, scanPos)
let deviceHeightA = nextFloat(inputData, scanPos)
let deviceHeightB = nextFloat(inputData, scanPos)
let errorLimit = nextFloat(inputData, scanPos)
let radiansPerDegree = arctan2(1.0, 1.0) / 45.0
let observerA = -baselineSpan * 0.5
let observerB = baselineSpan * 0.5

for caseIndex in 1 .. caseCount:
  let elevationA = nextFloat(inputData, scanPos)
  let elevationB = nextFloat(inputData, scanPos)
  let azimuthA = nextFloat(inputData, scanPos)
  let azimuthB = nextFloat(inputData, scanPos)
  appendOutput($(caseIndex))
  outputBuffer.add ' '
  if elevationA <= 0.0 or elevationA >= 90.0 or elevationB <= 0.0 or elevationB >= 90.0 or azimuthA <= 0.0 or azimuthA >= 90.0 or azimuthB <= 90.0 or azimuthB >= 180.0:
    appendOutput("DISQUALIFIED")
    outputBuffer.add '\n'
    continue
  let cosElevationA = cos(radiansPerDegree * elevationA)
  let sinElevationA = sin(radiansPerDegree * elevationA)
  let cosElevationB = cos(radiansPerDegree * elevationB)
  let sinElevationB = sin(radiansPerDegree * elevationB)
  let cosAzimuthA = cos(radiansPerDegree * azimuthA)
  let sinAzimuthA = sin(radiansPerDegree * azimuthA)
  let cosAzimuthB = cos(radiansPerDegree * azimuthB)
  let sinAzimuthB = sin(radiansPerDegree * azimuthB)
  let directionXA = cosElevationA * cosAzimuthA
  let directionYA = cosElevationA * sinAzimuthA
  let directionZA = sinElevationA
  let directionXB = cosElevationB * cosAzimuthB
  let directionYB = cosElevationB * sinAzimuthB
  let directionZB = sinElevationB
  let planeA = observerA * directionYA
  let planeB = observerB * directionYB
  let denominator = directionYB * directionXA - directionYA * directionXB
  if abs(denominator) < angleEpsilon:
    appendOutput("DIV BY ZERO")
    outputBuffer.add '\n'
    continue
  let crossX = (planeB * directionXA - planeA * directionXB) / denominator
  let crossY = (planeB * directionYA - planeA * directionYB) / denominator
  var reachA = 0.0
  var reachB = 0.0
  if abs(directionXA) >= abs(directionYA):
    reachA = (crossX - observerA) / directionXA
  else:
    reachA = crossY / directionYA
  if abs(directionXB) >= abs(directionYB):
    reachB = (crossX - observerB) / directionXB
  else:
    reachB = crossY / directionYB
  let sightHeightA = deviceHeightA + reachA * directionZA
  let sightHeightB = deviceHeightB + reachB * directionZB
  if abs(sightHeightA - sightHeightB) > errorLimit:
    appendOutput("ERROR")
  else:
    appendOutput($(int((sightHeightA + sightHeightB) * 0.5 + 0.5)))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
