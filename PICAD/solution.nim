import algorithm

const digitBase = 48
const flushBlockBytes = 1 shl 17

proc skipSpaces(inputData: string, scanPos: var int) =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos = scanPos + 1

proc hasToken(inputData: string, scanPos: int): bool =
  var pos = scanPos
  while pos < inputData.len and inputData[pos] <= ' ':
    pos = pos + 1
  return pos < inputData.len

proc nextInt(inputData: string, scanPos: var int): int =
  skipSpaces(inputData, scanPos)
  var negative = false
  if scanPos < inputData.len and inputData[scanPos] == '-':
    negative = true
    scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - digitBase
    scanPos = scanPos + 1
  if negative:
    return -value
  return value

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var scanPos = 0
var outputBuffer: string
var arrivalTimes: seq[int] = @[]
var departureTimes: seq[int] = @[]
var criticalTimes: seq[int] = @[]

while hasToken(inputData, scanPos):
  var crimeStart = nextInt(inputData, scanPos)
  var crimeEnd = nextInt(inputData, scanPos)
  var peopleCount = nextInt(inputData, scanPos)

  arrivalTimes.setLen(peopleCount)
  departureTimes.setLen(peopleCount)
  criticalTimes.setLen(2 * peopleCount + 2)

  for personIndex in 0 ..< peopleCount:
    var arrival = nextInt(inputData, scanPos)
    var departure = nextInt(inputData, scanPos)
    arrivalTimes[personIndex] = arrival
    departureTimes[personIndex] = departure
    criticalTimes[2 * personIndex] = arrival
    criticalTimes[2 * personIndex + 1] = departure

  criticalTimes[2 * peopleCount] = crimeStart
  criticalTimes[2 * peopleCount + 1] = crimeEnd

  sort(arrivalTimes, system.cmp[int])
  sort(departureTimes, system.cmp[int])
  sort(criticalTimes, system.cmp[int])

  var uniqueCount = 0
  for timeIndex in 0 ..< criticalTimes.len:
    if timeIndex == 0 or criticalTimes[timeIndex] != criticalTimes[timeIndex - 1]:
      criticalTimes[uniqueCount] = criticalTimes[timeIndex]
      uniqueCount = uniqueCount + 1
  criticalTimes.setLen(uniqueCount)

  var presentCount = 0
  var arrivalIndex = 0
  var departureIndex = 0
  var minPresent = high(int)
  var maxPresent = -1

  for timeIndex in 0 ..< criticalTimes.len:
    var moment = criticalTimes[timeIndex]
    while arrivalIndex < peopleCount and arrivalTimes[arrivalIndex] <= moment:
      presentCount = presentCount + 1
      arrivalIndex = arrivalIndex + 1
    if crimeStart <= moment and moment <= crimeEnd:
      if presentCount < minPresent: minPresent = presentCount
      if presentCount > maxPresent: maxPresent = presentCount
    while departureIndex < peopleCount and departureTimes[departureIndex] <= moment:
      presentCount = presentCount - 1
      departureIndex = departureIndex + 1
    if timeIndex + 1 < criticalTimes.len and moment < crimeEnd and criticalTimes[timeIndex + 1] > crimeStart:
      if presentCount < minPresent: minPresent = presentCount
      if presentCount > maxPresent: maxPresent = presentCount

  outputBuffer.add $minPresent
  outputBuffer.add ' '
  outputBuffer.add $maxPresent
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
