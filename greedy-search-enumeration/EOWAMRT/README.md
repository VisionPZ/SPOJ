<https://www.spoj.com/problems/EOWAMRT/>

## Problem

Robots move on a plane and share data instantly whenever two are within wireless range. Starting with only the first robot informed, list every robot that knows the data by the end of the simulation.

Input holds datasets until `0 0 0`. A dataset starts with `N T R`, the robot count, period length, and wireless range. Each robot has a nickname line, then triples `t x y` for time zero and `t vx vy` for each later velocity change. Positions and velocities may be negative. Output the nicknames of all informed robots in dictionary order, one per line.

| item | bound |
|---|---|
| robots `N` | 1 to 100 |
| period `T` | 1 to 1000 |
| range `R` | 1 to 10 |
| judge limit | 1000 ms, 1536 MB |

Each route is piecewise linear, and the last time stamp equals `T`.

Sample input:

```
3 5 10
red
0 0 0
5 0 0
green
0 5 5
5 6 1
blue
0 40 5
5 0 0
3 10 5
atom
0 47 32
5 -10 -7
10 1 0
pluto
0 0 0
7 0 0
10 3 3
gesicht
0 25 7
5 -7 -2
10 -1 10
4 100 7
impulse
0 -500 0
100 10 1
freedom
0 -491 0
100 9 2
destiny
0 -472 0
100 7 4
strike
0 -482 0
100 8 3
0 0 0
```

Sample output:

```
blue
green
red
atom
gesicht
pluto
freedom
impulse
strike
```

## Idea

Treat each pair of robots as a door that opens during certain time windows, like a train connection timetable. Compute every window when the pair is close enough, then spread information through those windows in time order. Relative motion turns each window into a quadratic inequality. The takeaway is that separating geometry from propagation keeps both parts small.

## Why It Works

1. On a merged interval both robots use constant velocities, so their relative motion is linear.
2. Squared distance becomes a quadratic `a*t*t + b*t + c`, where `c` compares with `R*R`.
3. The roots of the quadratic mark entry and exit from the wireless range.
4. A robot learns data at the start of the first contact window whose end is not before its own learning time.
5. Repeatedly picking the earliest informed robot spreads data in chronological order.

| term | meaning |
|---|---|
| `contactIntervals` | time windows when one pair is within range |
| `relativeVelocityX` | horizontal speed difference of a pair |
| `knownTime` | earliest time each robot receives the data |
| `timeEpsilon` | tolerance for float comparisons |

The problem guarantees clean crossings, so no tangency needs special handling.

In the first sample dataset, red meets green during `[0.000, 0.553]` and green meets blue during `[4.331, 5.000]`. Red starts at time zero, green learns at zero, and blue learns at `4.331`, before the period ends.

The final filter keeps robots with `knownTime` at most `T` plus tolerance.

## Code

**Input and types.** The reader loads input once, parses signed integers and words, and defines the route records.

```nim
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
```

The scanner keeps minus signs for coordinates and speeds.
A route stores each linear segment separately.
One buffer handles all output lines.

**Contact windows.** Merged time intervals are solved for range entry and exit.

```nim
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
```

Segment boundaries split the period into constant-velocity pieces.
Adjacent windows are merged before propagation.
A negative discriminant means the pair stays out of range.

**Propagation.** The earliest informed robot is expanded until no more data can move.

```nim
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
```

Each pair's windows are stored in both directions.
A window starting before the learning time still works.
The first usable window gives the earliest learning time.

**Report.** Informed nicknames are sorted and written.

```nim
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
```

The filter uses the full period as the deadline.
Dictionary order comes from string comparison.
The final flush emits the last lines.

## Complexity

Contact windows are computed per pair, then propagation expands each robot once.

| phase | time | space |
|---|---|---|
| input read | one pass over route tokens | one input string |
| contact windows | pairs times merged segment count | windows per ordered pair |
| propagation | robots squared times windows per pair | learning times |
| output | one line per informed robot | block buffer |

| measure | Big O |
|---|---|
| time per dataset | `O(N^2 * S + N^2 * W)` |
| space per dataset | `O(N^2 * W)` |

A time-step simulation over the whole period would miss short windows or repeat far more work.

The quadratic solves turn motion into a short list of exact windows.
