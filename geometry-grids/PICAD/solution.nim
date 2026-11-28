import algorithm

const digitBase = 48
const flushBlockBytes = 1 shl 17

proc skipSpaces(inputData: string, i: var int) =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1

proc hasToken(inputData: string, i: int): bool =
  var j = i
  while j < inputData.len and inputData[j] <= ' ':
    j = j + 1
  return j < inputData.len

proc nextInt(inputData: string, i: var int): int =
  skipSpaces(inputData, i)
  var negative = false
  if i < inputData.len and inputData[i] == '-':
    negative = true
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - digitBase
    i = i + 1
  if negative:
    return -value
  return value

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
var outputBuffer: string
var arrivalTimes: seq[int] = @[]
var departureTimes: seq[int] = @[]
var criticalTimes: seq[int] = @[]

while hasToken(inputData, i):
  var crimeStart = nextInt(inputData, i)
  var crimeEnd = nextInt(inputData, i)
  var peopleCount = nextInt(inputData, i)

  arrivalTimes.setLen(peopleCount)
  departureTimes.setLen(peopleCount)
  criticalTimes.setLen(2 * peopleCount + 2)

  for j in 0 ..< peopleCount:
    var arrival = nextInt(inputData, i)
    var departure = nextInt(inputData, i)
    arrivalTimes[j] = arrival
    departureTimes[j] = departure
    criticalTimes[2 * j] = arrival
    criticalTimes[2 * j + 1] = departure

  criticalTimes[2 * peopleCount] = crimeStart
  criticalTimes[2 * peopleCount + 1] = crimeEnd

  sort(arrivalTimes, system.cmp[int])
  sort(departureTimes, system.cmp[int])
  sort(criticalTimes, system.cmp[int])

  var uniqueCount = 0
  for j in 0 ..< criticalTimes.len:
    if j == 0 or criticalTimes[j] != criticalTimes[j - 1]:
      criticalTimes[uniqueCount] = criticalTimes[j]
      uniqueCount = uniqueCount + 1
  criticalTimes.setLen(uniqueCount)

  var presentCount = 0
  var k = 0
  var l = 0
  var minPresent = high(int)
  var maxPresent = -1

  for j in 0 ..< criticalTimes.len:
    var moment = criticalTimes[j]
    while k < peopleCount and arrivalTimes[k] <= moment:
      presentCount = presentCount + 1
      k = k + 1
    if crimeStart <= moment and moment <= crimeEnd:
      if presentCount < minPresent: minPresent = presentCount
      if presentCount > maxPresent: maxPresent = presentCount
    while l < peopleCount and departureTimes[l] <= moment:
      presentCount = presentCount - 1
      l = l + 1
    if j + 1 < criticalTimes.len and moment < crimeEnd and criticalTimes[j + 1] > crimeStart:
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
