const flushBlockBytes = 1 shl 17
const unreachableCost = int64(1 shl 60)

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc ferryCost(neededWater: int64, legLength: int, capacity: int): int64 =
  if neededWater == 0:
    return int64(legLength)
  if 2 * legLength >= capacity:
    if neededWater + int64(legLength) > int64(capacity):
      return unreachableCost
    return neededWater + int64(legLength)
  let finalLoad = int64(capacity - legLength)
  if neededWater <= finalLoad:
    return neededWater + int64(legLength)
  let depositPerTrip = int64(capacity - 2 * legLength)
  let extraWater = neededWater - finalLoad
  var roundTrips = extraWater div depositPerTrip
  if extraWater mod depositPerTrip != 0:
    roundTrips += 1
  return neededWater + int64(legLength) + 2 * int64(legLength) * roundTrips

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let restpointCount = nextInt(inputData, scanPos)
  let pathCount = nextInt(inputData, scanPos)
  let capacity = nextInt(inputData, scanPos)
  var edgeFrom = newSeq[int](0)
  var edgeTo = newSeq[int](0)
  var edgeLength = newSeq[int](0)
  for pathIndex in 0 .. pathCount - 1:
    let firstPoint = nextInt(inputData, scanPos)
    let secondPoint = nextInt(inputData, scanPos)
    let pathLength = nextInt(inputData, scanPos)
    if pathLength > capacity:
      continue
    edgeFrom.add(firstPoint)
    edgeTo.add(secondPoint)
    edgeLength.add(pathLength)
    edgeFrom.add(secondPoint)
    edgeTo.add(firstPoint)
    edgeLength.add(pathLength)
  var needed = newSeq[int64](restpointCount + 1)
  var settled = newSeq[bool](restpointCount + 1)
  for point in 1 .. restpointCount:
    needed[point] = unreachableCost
    settled[point] = false
  needed[restpointCount] = 0
  for stepIndex in 0 .. restpointCount - 1:
    var chosenPoint = -1
    var chosenCost = unreachableCost
    for point in 1 .. restpointCount:
      if not settled[point] and needed[point] < chosenCost:
        chosenPoint = point
        chosenCost = needed[point]
    if chosenPoint == -1:
      break
    settled[chosenPoint] = true
    for edgeIndex in 0 .. edgeFrom.len - 1:
      if edgeFrom[edgeIndex] != chosenPoint:
        continue
      let neighborPoint = edgeTo[edgeIndex]
      if settled[neighborPoint]:
        continue
      let candidateCost = ferryCost(chosenCost, edgeLength[edgeIndex], capacity)
      if candidateCost < needed[neighborPoint]:
        needed[neighborPoint] = candidateCost
  if needed[1] >= unreachableCost:
    appendOutput("-1\n")
  else:
    appendOutput($needed[1])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
