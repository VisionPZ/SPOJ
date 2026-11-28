const flushBlockBytes = 1 shl 17
const infiniteDistance = 1 shl 28

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
var roadGrid = newSeq[seq[int]](cityCount)
for cityIndex in 0 .. cityCount - 1:
  roadGrid[cityIndex] = newSeq[int](cityCount)
  for neighborIndex in 0 .. cityCount - 1:
    roadGrid[cityIndex][neighborIndex] = infiniteDistance
  roadGrid[cityIndex][cityIndex] = 0
for roadIndex in 0 .. roadCount - 1:
  let firstCity = nextInt(inputData, scanPos)
  let secondCity = nextInt(inputData, scanPos)
  let roadLength = nextInt(inputData, scanPos)
  if roadLength < roadGrid[firstCity][secondCity]:
    roadGrid[firstCity][secondCity] = roadLength
    roadGrid[secondCity][firstCity] = roadLength

let storeCount = nextInt(inputData, scanPos)
var storeCities = newSeq[int](storeCount)
for storeIndex in 0 .. storeCount - 1:
  storeCities[storeIndex] = nextInt(inputData, scanPos)
let firstHome = nextInt(inputData, scanPos)
let secondHome = nextInt(inputData, scanPos)
let positionCount = storeCount + 2
var positionCities = newSeq[int](positionCount)
for storeIndex in 0 .. storeCount - 1:
  positionCities[storeIndex] = storeCities[storeIndex]
positionCities[storeCount] = firstHome
positionCities[storeCount + 1] = secondHome

var sourceDistances = newSeq[seq[int]](positionCount)
for sourceIndex in 0 .. positionCount - 1:
  var distances = newSeq[int](cityCount)
  var settled = newSeq[bool](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    distances[cityIndex] = infiniteDistance
    settled[cityIndex] = false
  distances[positionCities[sourceIndex]] = 0
  for searchStep in 0 .. cityCount - 1:
    var nearestCity = -1
    var nearestDistance = infiniteDistance
    for cityIndex in 0 .. cityCount - 1:
      if not settled[cityIndex] and distances[cityIndex] < nearestDistance:
        nearestDistance = distances[cityIndex]
        nearestCity = cityIndex
    if nearestCity < 0:
      break
    settled[nearestCity] = true
    for neighborIndex in 0 .. cityCount - 1:
      let edgeLength = roadGrid[nearestCity][neighborIndex]
      if edgeLength < infiniteDistance and nearestDistance + edgeLength < distances[neighborIndex]:
        distances[neighborIndex] = nearestDistance + edgeLength
  sourceDistances[sourceIndex] = distances

let subsetCount = 1 shl storeCount
var bestCosts = newSeq[int](subsetCount * positionCount * positionCount)
for costIndex in 0 .. bestCosts.len - 1:
  bestCosts[costIndex] = infiniteDistance
bestCosts[(0 * positionCount + storeCount) * positionCount + storeCount + 1] = 0
for subset in 0 .. subsetCount - 1:
  for firstPosition in 0 .. positionCount - 1:
    for secondPosition in 0 .. positionCount - 1:
      let currentCost = bestCosts[(subset * positionCount + firstPosition) * positionCount + secondPosition]
      if currentCost >= infiniteDistance:
        continue
      for storeIndex in 0 .. storeCount - 1:
        if (subset and (1 shl storeIndex)) != 0:
          continue
        let nextSubset = subset or (1 shl storeIndex)
        let storeCity = storeCities[storeIndex]
        let firstMove = sourceDistances[firstPosition][storeCity]
        if firstMove < infiniteDistance:
          let nextCost = currentCost + firstMove
          let nextIndex = (nextSubset * positionCount + storeIndex) * positionCount + secondPosition
          if nextCost < bestCosts[nextIndex]:
            bestCosts[nextIndex] = nextCost
        let secondMove = sourceDistances[secondPosition][storeCity]
        if secondMove < infiniteDistance:
          let nextCost = currentCost + secondMove
          let nextIndex = (nextSubset * positionCount + firstPosition) * positionCount + storeIndex
          if nextCost < bestCosts[nextIndex]:
            bestCosts[nextIndex] = nextCost

let fullSubset = subsetCount - 1
var minimumDistance = infiniteDistance
for firstPosition in 0 .. positionCount - 1:
  for secondPosition in 0 .. positionCount - 1:
    let candidateDistance = bestCosts[(fullSubset * positionCount + firstPosition) * positionCount + secondPosition]
    if candidateDistance < minimumDistance:
      minimumDistance = candidateDistance
appendOutput($minimumDistance)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
