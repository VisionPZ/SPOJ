const flushBlockBytes = 1 shl 17
const unreachableCost = 1000000000

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

let cityCount = nextInt(inputData, scanPos)
let roadCount = nextInt(inputData, scanPos)
var roadStarts = newSeq[int](roadCount)
var roadEnds = newSeq[int](roadCount)
var roadPayCities = newSeq[int](roadCount)
var roadAdvancePrices = newSeq[int](roadCount)
var roadArrivalPrices = newSeq[int](roadCount)
for roadIndex in 0 .. roadCount - 1:
  roadStarts[roadIndex] = nextInt(inputData, scanPos) - 1
  roadEnds[roadIndex] = nextInt(inputData, scanPos) - 1
  roadPayCities[roadIndex] = nextInt(inputData, scanPos) - 1
  roadAdvancePrices[roadIndex] = nextInt(inputData, scanPos)
  roadArrivalPrices[roadIndex] = nextInt(inputData, scanPos)

let maskCount = 1 shl roadCount
let stateCount = cityCount * maskCount
var bestCosts = newSeq[int](stateCount)
for stateIndex in 0 .. stateCount - 1:
  bestCosts[stateIndex] = unreachableCost
bestCosts[0] = 0
var inQueue = newSeq[bool](stateCount)
var pendingStates = newSeq[int]()
pendingStates.add 0
inQueue[0] = true
var queueHead = 0

while queueHead < pendingStates.len:
  let stateIndex = pendingStates[queueHead]
  queueHead += 1
  inQueue[stateIndex] = false
  let currentCity = stateIndex div maskCount
  let currentMask = stateIndex mod maskCount
  let currentCost = bestCosts[stateIndex]
  for roadIndex in 0 .. roadCount - 1:
    let roadBit = 1 shl roadIndex
    if roadPayCities[roadIndex] == currentCity and (currentMask and roadBit) == 0:
      let nextMask = currentMask or roadBit
      let nextStateIndex = currentCity * maskCount + nextMask
      let nextCost = currentCost + roadAdvancePrices[roadIndex]
      if nextCost < bestCosts[nextStateIndex]:
        bestCosts[nextStateIndex] = nextCost
        if not inQueue[nextStateIndex]:
          pendingStates.add nextStateIndex
          inQueue[nextStateIndex] = true
    if roadStarts[roadIndex] == currentCity:
      var travelCost = roadArrivalPrices[roadIndex]
      if (currentMask and roadBit) != 0:
        travelCost = 0
      let nextStateIndex = roadEnds[roadIndex] * maskCount + currentMask
      let nextCost = currentCost + travelCost
      if nextCost < bestCosts[nextStateIndex]:
        bestCosts[nextStateIndex] = nextCost
        if not inQueue[nextStateIndex]:
          pendingStates.add nextStateIndex
          inQueue[nextStateIndex] = true

var answer = unreachableCost
for maskIndex in 0 .. maskCount - 1:
  let candidate = bestCosts[(cityCount - 1) * maskCount + maskIndex]
  if candidate < answer:
    answer = candidate
if answer >= unreachableCost:
  appendOutput("impossible\n")
else:
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
