const flushBlockBytes = 1 shl 17
const unreachableCost = int64(1) shl 60

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

let requiredSets = int64(nextInt(inputData, scanPos))
let startX = int64(nextInt(inputData, scanPos))
let startY = int64(nextInt(inputData, scanPos))
let startZ = int64(nextInt(inputData, scanPos))
let shopCount = nextInt(inputData, scanPos)

var shopX = newSeq[int64](shopCount)
var shopY = newSeq[int64](shopCount)
var shopZ = newSeq[int64](shopCount)
var monitorsAvailable = newSeq[int64](shopCount)
var keyboardsAvailable = newSeq[int64](shopCount)
var processorsAvailable = newSeq[int64](shopCount)
for shopIndex in 0 .. shopCount - 1:
  shopX[shopIndex] = int64(nextInt(inputData, scanPos))
  shopY[shopIndex] = int64(nextInt(inputData, scanPos))
  shopZ[shopIndex] = int64(nextInt(inputData, scanPos))
  monitorsAvailable[shopIndex] = int64(nextInt(inputData, scanPos))
  keyboardsAvailable[shopIndex] = int64(nextInt(inputData, scanPos))
  processorsAvailable[shopIndex] = int64(nextInt(inputData, scanPos))

let nodeCount = shopCount + 1
var travelCosts = newSeq[seq[int64]](nodeCount)
for firstNode in 0 .. nodeCount - 1:
  travelCosts[firstNode] = newSeq[int64](nodeCount)
  for secondNode in 0 .. nodeCount - 1:
    if firstNode == secondNode:
      travelCosts[firstNode][secondNode] = 0
    else:
      var deltaX = int64(0)
      var deltaY = int64(0)
      var deltaZ = int64(0)
      if firstNode == 0:
        deltaX = shopX[secondNode - 1] - startX
        deltaY = shopY[secondNode - 1] - startY
        deltaZ = shopZ[secondNode - 1] - startZ
      elif secondNode == 0:
        deltaX = shopX[firstNode - 1] - startX
        deltaY = shopY[firstNode - 1] - startY
        deltaZ = shopZ[firstNode - 1] - startZ
      else:
        deltaX = shopX[firstNode - 1] - shopX[secondNode - 1]
        deltaY = shopY[firstNode - 1] - shopY[secondNode - 1]
        deltaZ = shopZ[firstNode - 1] - shopZ[secondNode - 1]
      travelCosts[firstNode][secondNode] = deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ

for viaNode in 0 .. nodeCount - 1:
  for firstNode in 0 .. nodeCount - 1:
    for secondNode in 0 .. nodeCount - 1:
      let candidateCost = travelCosts[firstNode][viaNode] + travelCosts[viaNode][secondNode]
      if candidateCost < travelCosts[firstNode][secondNode]:
        travelCosts[firstNode][secondNode] = candidateCost

let maskCount = 1 shl shopCount
var bestCosts = newSeq[seq[int64]](maskCount)
var monitorTotals = newSeq[int64](maskCount)
var keyboardTotals = newSeq[int64](maskCount)
var processorTotals = newSeq[int64](maskCount)
for mask in 0 .. maskCount - 1:
  bestCosts[mask] = newSeq[int64](shopCount)
  for shopIndex in 0 .. shopCount - 1:
    bestCosts[mask][shopIndex] = unreachableCost
  for shopIndex in 0 .. shopCount - 1:
    if (mask and (1 shl shopIndex)) != 0:
      monitorTotals[mask] += monitorsAvailable[shopIndex]
      keyboardTotals[mask] += keyboardsAvailable[shopIndex]
      processorTotals[mask] += processorsAvailable[shopIndex]
  if monitorTotals[mask] > requiredSets:
    monitorTotals[mask] = requiredSets
  if keyboardTotals[mask] > requiredSets:
    keyboardTotals[mask] = requiredSets
  if processorTotals[mask] > requiredSets:
    processorTotals[mask] = requiredSets

for shopIndex in 0 .. shopCount - 1:
  let singleMask = 1 shl shopIndex
  bestCosts[singleMask][shopIndex] = travelCosts[0][shopIndex + 1]

for mask in 1 .. maskCount - 1:
  for lastShop in 0 .. shopCount - 1:
    let currentCost = bestCosts[mask][lastShop]
    if currentCost >= unreachableCost:
      continue
    for nextShop in 0 .. shopCount - 1:
      if (mask and (1 shl nextShop)) != 0:
        continue
      let nextMask = mask or (1 shl nextShop)
      let candidateCost = currentCost + travelCosts[lastShop + 1][nextShop + 1]
      if candidateCost < bestCosts[nextMask][nextShop]:
        bestCosts[nextMask][nextShop] = candidateCost

var minimumCost = unreachableCost
for mask in 1 .. maskCount - 1:
  if monitorTotals[mask] < requiredSets or keyboardTotals[mask] < requiredSets or processorTotals[mask] < requiredSets:
    continue
  for lastShop in 0 .. shopCount - 1:
    if bestCosts[mask][lastShop] < minimumCost:
      minimumCost = bestCosts[mask][lastShop]

appendOutput($minimumCost)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
