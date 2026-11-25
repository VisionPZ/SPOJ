import math

const flushBlockBytes = 1 shl 17
const timeEpsilon = 1e-9

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos = pos + 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos = pos + 1
  return signValue * value

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

type TimeInterval = tuple[startTime, endTime: float]

type RobotRoute = object
  nickname: string
  startTime: seq[float]
  startX: seq[float]
  startY: seq[float]
  velocityX: seq[float]
  velocityY: seq[float]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc segmentIndex(route: RobotRoute, timeValue: float): int =
  result = 0
  while result < route.startTime.len - 1 and route.startTime[result + 1] <= timeValue + timeEpsilon:
    result += 1

proc contactIntervals(firstRoute: RobotRoute, secondRoute: RobotRoute,
                      radius: float, period: float): seq[TimeInterval] =
  var breakpoints = newSeq[float]()
  breakpoints.add 0.0
  breakpoints.add period
  for routeIndex in 0 .. 1:
    let chosenRoute = if routeIndex == 0: firstRoute else: secondRoute
    for segmentIndexValue in 0 .. chosenRoute.startTime.len - 1:
      breakpoints.add chosenRoute.startTime[segmentIndexValue]
  for sortIndex in 1 .. breakpoints.len - 1:
    let currentValue = breakpoints[sortIndex]
    var insertIndex = sortIndex - 1
    while insertIndex >= 0 and breakpoints[insertIndex] > currentValue:
      breakpoints[insertIndex + 1] = breakpoints[insertIndex]
      insertIndex -= 1
    breakpoints[insertIndex + 1] = currentValue
  var rawIntervals = newSeq[TimeInterval]()
  for breakpointIndex in 0 .. breakpoints.len - 2:
    let intervalStart = breakpoints[breakpointIndex]
    let intervalEnd = breakpoints[breakpointIndex + 1]
    let intervalLength = intervalEnd - intervalStart
    if intervalLength <= timeEpsilon:
      continue
    let firstSegment = segmentIndex(firstRoute, intervalStart)
    let secondSegment = segmentIndex(secondRoute, intervalStart)
    let firstX = firstRoute.startX[firstSegment] +
        firstRoute.velocityX[firstSegment] * (intervalStart - firstRoute.startTime[firstSegment])
    let firstY = firstRoute.startY[firstSegment] +
        firstRoute.velocityY[firstSegment] * (intervalStart - firstRoute.startTime[firstSegment])
    let secondX = secondRoute.startX[secondSegment] +
        secondRoute.velocityX[secondSegment] * (intervalStart - secondRoute.startTime[secondSegment])
    let secondY = secondRoute.startY[secondSegment] +
        secondRoute.velocityY[secondSegment] * (intervalStart - secondRoute.startTime[secondSegment])
    let relativeX = firstX - secondX
    let relativeY = firstY - secondY
    let relativeVelocityX = firstRoute.velocityX[firstSegment] - secondRoute.velocityX[secondSegment]
    let relativeVelocityY = firstRoute.velocityY[firstSegment] - secondRoute.velocityY[secondSegment]
    let squareA = relativeVelocityX * relativeVelocityX + relativeVelocityY * relativeVelocityY
    let linearB = 2.0 * (relativeX * relativeVelocityX + relativeY * relativeVelocityY)
    let constantC = relativeX * relativeX + relativeY * relativeY - radius * radius
    if squareA <= timeEpsilon:
      if constantC <= timeEpsilon:
        rawIntervals.add (intervalStart, intervalEnd)
      continue
    let discriminant = linearB * linearB - 4.0 * squareA * constantC
    if discriminant < 0.0:
      continue
    let rootValue = sqrt(discriminant)
    let lowerRoot = (-linearB - rootValue) / (2.0 * squareA)
    let upperRoot = (-linearB + rootValue) / (2.0 * squareA)
    if upperRoot < -timeEpsilon or lowerRoot > intervalLength + timeEpsilon:
      continue
    var contactStart = intervalStart + lowerRoot
    var contactEnd = intervalStart + upperRoot
    if contactStart < intervalStart:
      contactStart = intervalStart
    if contactEnd > intervalEnd:
      contactEnd = intervalEnd
    if contactEnd - contactStart > timeEpsilon:
      rawIntervals.add (contactStart, contactEnd)
  var result = newSeq[TimeInterval]()
  for candidate in rawIntervals:
    if result.len > 0 and candidate.startTime <= result[result.len - 1].endTime + timeEpsilon:
      if candidate.endTime > result[result.len - 1].endTime:
        result[result.len - 1].endTime = candidate.endTime
    else:
      result.add candidate
  return result

while true:
  let robotCount = nextInt(inputData, scanPos)
  let period = nextInt(inputData, scanPos)
  let radiusInteger = nextInt(inputData, scanPos)
  if robotCount == 0 and period == 0 and radiusInteger == 0:
    break
  let radius = float(radiusInteger)
  var routes = newSeq[RobotRoute]()
  for robotIndex in 0 .. robotCount - 1:
    var route: RobotRoute
    route.nickname = nextWord(inputData, scanPos)
    route.startTime = newSeq[float]()
    route.startX = newSeq[float]()
    route.startY = newSeq[float]()
    route.velocityX = newSeq[float]()
    route.velocityY = newSeq[float]()
    var previousTime = 0
    var currentX = 0.0
    var currentY = 0.0
    while true:
      let timeStamp = nextInt(inputData, scanPos)
      let firstValue = nextInt(inputData, scanPos)
      let secondValue = nextInt(inputData, scanPos)
      if timeStamp == 0:
        currentX = float(firstValue)
        currentY = float(secondValue)
      else:
        route.startTime.add float(previousTime)
        route.startX.add currentX
        route.startY.add currentY
        route.velocityX.add float(firstValue)
        route.velocityY.add float(secondValue)
        currentX += float(firstValue * (timeStamp - previousTime))
        currentY += float(secondValue * (timeStamp - previousTime))
      previousTime = timeStamp
      if timeStamp == period:
        break
    routes.add route
  let pairWidth = robotCount
  var contacts = newSeq[seq[TimeInterval]](pairWidth * pairWidth)
  for firstRobot in 0 .. robotCount - 1:
    for secondRobot in firstRobot + 1 .. robotCount - 1:
      let foundIntervals = contactIntervals(routes[firstRobot], routes[secondRobot], radius, float(period))
      contacts[firstRobot * pairWidth + secondRobot] = foundIntervals
      contacts[secondRobot * pairWidth + firstRobot] = foundIntervals
  var knownTime = newSeq[float](robotCount)
  var processed = newSeq[bool](robotCount)
  for robotIndex in 0 .. robotCount - 1:
    knownTime[robotIndex] = 1e30
    processed[robotIndex] = false
  knownTime[0] = 0.0
  for selectionIndex in 0 .. robotCount - 1:
    var chosenRobot = -1
    for robotIndex in 0 .. robotCount - 1:
      if not processed[robotIndex] and (chosenRobot == -1 or knownTime[robotIndex] < knownTime[chosenRobot]):
        chosenRobot = robotIndex
    if chosenRobot == -1 or knownTime[chosenRobot] > 1e29:
      break
    processed[chosenRobot] = true
    let currentTime = knownTime[chosenRobot]
    for neighborRobot in 0 .. robotCount - 1:
      if neighborRobot == chosenRobot:
        continue
      let intervalList = contacts[chosenRobot * pairWidth + neighborRobot]
      for contact in intervalList:
        if contact.endTime + timeEpsilon >= currentTime:
          var learnTime = contact.startTime
          if learnTime < currentTime:
            learnTime = currentTime
          if learnTime < knownTime[neighborRobot]:
            knownTime[neighborRobot] = learnTime
          break
  var informedNames = newSeq[string]()
  for robotIndex in 0 .. robotCount - 1:
    if knownTime[robotIndex] <= float(period) + timeEpsilon:
      informedNames.add routes[robotIndex].nickname
  for sortIndex in 1 .. informedNames.len - 1:
    let currentName = informedNames[sortIndex]
    var insertIndex = sortIndex - 1
    while insertIndex >= 0 and informedNames[insertIndex] > currentName:
      informedNames[insertIndex + 1] = informedNames[insertIndex]
      insertIndex -= 1
    informedNames[insertIndex + 1] = currentName
  for nickname in informedNames:
    appendOutput(nickname)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
