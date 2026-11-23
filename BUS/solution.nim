const infiniteTime = 1000000000
const flushBlockBytes = 1 shl 17

type BusPair = object
  firstBus: int
  secondBus: int
  periodLength: int
  meetingTimes: seq[int]

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  return value

proc greatestCommonDivisor(firstValue, secondValue: int): int =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue

proc nextMeetingTime(meetingTimes: seq[int], periodLength, currentTime: int): int =
  let withinPeriod = currentTime mod periodLength
  var lowIndex = 0
  var highIndex = meetingTimes.len
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if meetingTimes[middleIndex] < withinPeriod:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  if lowIndex < meetingTimes.len:
    return currentTime - withinPeriod + meetingTimes[lowIndex]
  return currentTime - withinPeriod + periodLength + meetingTimes[0]

var inputData: string
var inputLine: string
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var scanPos = 0
var outputBuffer: string

while true:
  let busCount = nextInt(inputData, scanPos)
  if busCount == 0: break
  var routes: seq[seq[int]] = @[]
  for busIndex in 0 .. busCount - 1:
    let stopCount = nextInt(inputData, scanPos)
    var route: seq[int] = @[]
    for stopIndex in 0 .. stopCount - 1:
      route.add nextInt(inputData, scanPos)
    routes.add route
  var pairList: seq[BusPair] = @[]
  for leftBusIndex in 0 .. busCount - 1:
    for rightBusIndex in leftBusIndex + 1 .. busCount - 1:
      let firstLength = routes[leftBusIndex].len
      let secondLength = routes[rightBusIndex].len
      let divisor = greatestCommonDivisor(firstLength, secondLength)
      let periodLength = firstLength div divisor * secondLength
      var meetingTimes: seq[int] = @[]
      for timeIndex in 0 .. periodLength - 1:
        if routes[leftBusIndex][timeIndex mod firstLength] == routes[rightBusIndex][timeIndex mod secondLength]:
          meetingTimes.add timeIndex
      if meetingTimes.len > 0:
        pairList.add BusPair(firstBus: leftBusIndex, secondBus: rightBusIndex,
                             periodLength: periodLength, meetingTimes: meetingTimes)
  var arrivalTimes = newSeq[seq[int]](busCount)
  for busIndex in 0 .. busCount - 1:
    arrivalTimes[busIndex] = newSeq[int](busCount)
    for sourceIndex in 0 .. busCount - 1:
      if busIndex == sourceIndex:
        arrivalTimes[busIndex][sourceIndex] = 0
      else:
        arrivalTimes[busIndex][sourceIndex] = infiniteTime
  for roundIndex in 0 .. busCount:
    var changed = false
    for busPair in pairList:
      let leftBus = busPair.firstBus
      let rightBus = busPair.secondBus
      let periodLength = busPair.periodLength
      let meetingTimes = busPair.meetingTimes
      for sourceIndex in 0 .. busCount - 1:
        if arrivalTimes[rightBus][sourceIndex] < infiniteTime:
          let candidate = nextMeetingTime(meetingTimes, periodLength, arrivalTimes[rightBus][sourceIndex])
          if candidate < arrivalTimes[leftBus][sourceIndex]:
            arrivalTimes[leftBus][sourceIndex] = candidate
            changed = true
        if arrivalTimes[leftBus][sourceIndex] < infiniteTime:
          let candidate = nextMeetingTime(meetingTimes, periodLength, arrivalTimes[leftBus][sourceIndex])
          if candidate < arrivalTimes[rightBus][sourceIndex]:
            arrivalTimes[rightBus][sourceIndex] = candidate
            changed = true
    if not changed: break
  var latestArrival = 0
  for busIndex in 0 .. busCount - 1:
    for sourceIndex in 0 .. busCount - 1:
      if arrivalTimes[busIndex][sourceIndex] > latestArrival:
        latestArrival = arrivalTimes[busIndex][sourceIndex]
  if latestArrival >= infiniteTime:
    outputBuffer.add "NEVER\n"
  else:
    outputBuffer.add $latestArrival
    outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
