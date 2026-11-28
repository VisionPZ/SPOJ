const infiniteTime = 1000000000
const flushBlockBytes = 1 shl 17

type BusPair = object
  firstBus: int
  secondBus: int
  periodLength: int
  meetingTimes: seq[int]

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
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
  var i = 0
  var j = meetingTimes.len
  while i < j:
    let k = (i + j) div 2
    if meetingTimes[k] < withinPeriod:
      i = k + 1
    else:
      j = k
  if i < meetingTimes.len:
    return currentTime - withinPeriod + meetingTimes[i]
  return currentTime - withinPeriod + periodLength + meetingTimes[0]

var inputData: string
var inputLine: string
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var i = 0
var outputBuffer: string

while true:
  let busCount = nextInt(inputData, i)
  if busCount == 0: break
  var routes: seq[seq[int]] = @[]
  for j in 0 .. busCount - 1:
    let stopCount = nextInt(inputData, i)
    var route: seq[int] = @[]
    for k in 0 .. stopCount - 1:
      route.add nextInt(inputData, i)
    routes.add route
  var pairList: seq[BusPair] = @[]
  for j in 0 .. busCount - 1:
    for k in j + 1 .. busCount - 1:
      let firstLength = routes[j].len
      let secondLength = routes[k].len
      let divisor = greatestCommonDivisor(firstLength, secondLength)
      let periodLength = firstLength div divisor * secondLength
      var meetingTimes: seq[int] = @[]
      for l in 0 .. periodLength - 1:
        if routes[j][l mod firstLength] == routes[k][l mod secondLength]:
          meetingTimes.add l
      if meetingTimes.len > 0:
        pairList.add BusPair(firstBus: j, secondBus: k,
                             periodLength: periodLength, meetingTimes: meetingTimes)
  var arrivalTimes = newSeq[seq[int]](busCount)
  for j in 0 .. busCount - 1:
    arrivalTimes[j] = newSeq[int](busCount)
    for k in 0 .. busCount - 1:
      if j == k:
        arrivalTimes[j][k] = 0
      else:
        arrivalTimes[j][k] = infiniteTime
  for j in 0 .. busCount:
    var changed = false
    for busPair in pairList:
      let leftBus = busPair.firstBus
      let rightBus = busPair.secondBus
      let periodLength = busPair.periodLength
      let meetingTimes = busPair.meetingTimes
      for k in 0 .. busCount - 1:
        if arrivalTimes[rightBus][k] < infiniteTime:
          let candidate = nextMeetingTime(meetingTimes, periodLength, arrivalTimes[rightBus][k])
          if candidate < arrivalTimes[leftBus][k]:
            arrivalTimes[leftBus][k] = candidate
            changed = true
        if arrivalTimes[leftBus][k] < infiniteTime:
          let candidate = nextMeetingTime(meetingTimes, periodLength, arrivalTimes[leftBus][k])
          if candidate < arrivalTimes[rightBus][k]:
            arrivalTimes[rightBus][k] = candidate
            changed = true
    if not changed: break
  var latestArrival = 0
  for j in 0 .. busCount - 1:
    for k in 0 .. busCount - 1:
      if arrivalTimes[j][k] > latestArrival:
        latestArrival = arrivalTimes[j][k]
  if latestArrival >= infiniteTime:
    outputBuffer.add "NEVER\n"
  else:
    outputBuffer.add $latestArrival
    outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
