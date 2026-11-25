import algorithm
import strutils

const flushBlockBytes = 1 shl 17
const missingValue = -1e100

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

proc nextReal(data: string, pos: var int): float =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    pos += 1
  return parseFloat(data[startPos .. pos - 1])

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type HullLine = object
  slope: float
  intercept: float
  present: bool

proc evaluate(hullLine: HullLine, coordinate: float): float =
  return hullLine.slope * coordinate + hullLine.intercept

proc compareFloat(leftValue: float, rightValue: float): int =
  if leftValue < rightValue:
    return -1
  if leftValue > rightValue:
    return 1
  return 0

proc insertHullLine(tree: var seq[HullLine], coordinates: seq[float],
                    nodeIndex: int, leftIndex: int, rightIndex: int,
                    incomingLine: HullLine) =
  var newLine = incomingLine
  if not tree[nodeIndex].present:
    tree[nodeIndex] = newLine
    return
  let middleIndex = (leftIndex + rightIndex) div 2
  if evaluate(newLine, coordinates[middleIndex]) > evaluate(tree[nodeIndex], coordinates[middleIndex]):
    swap tree[nodeIndex], newLine
  if leftIndex == rightIndex:
    return
  if evaluate(newLine, coordinates[leftIndex]) > evaluate(tree[nodeIndex], coordinates[leftIndex]):
    insertHullLine(tree, coordinates, nodeIndex * 2, leftIndex, middleIndex, newLine)
  elif evaluate(newLine, coordinates[rightIndex]) > evaluate(tree[nodeIndex], coordinates[rightIndex]):
    insertHullLine(tree, coordinates, nodeIndex * 2 + 1, middleIndex + 1, rightIndex, newLine)

proc queryHull(tree: seq[HullLine], coordinates: seq[float],
               nodeIndex: int, leftIndex: int, rightIndex: int,
               targetIndex: int): float =
  result = missingValue
  if tree[nodeIndex].present:
    result = evaluate(tree[nodeIndex], coordinates[targetIndex])
  if leftIndex == rightIndex:
    return
  let middleIndex = (leftIndex + rightIndex) div 2
  if targetIndex <= middleIndex:
    result = max(result, queryHull(tree, coordinates, nodeIndex * 2, leftIndex, middleIndex, targetIndex))
  else:
    result = max(result, queryHull(tree, coordinates, nodeIndex * 2 + 1, middleIndex + 1, rightIndex, targetIndex))

proc findCoordinate(coordinates: seq[float], target: float): int =
  var lowIndex = 0
  var highIndex = coordinates.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if coordinates[middleIndex] == target:
      return middleIndex
    if coordinates[middleIndex] < target:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  return 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let dayCount = nextInt(inputData, scanPos)
  let startingCapital = nextReal(inputData, scanPos)
  var moneRates = newSeq[float](dayCount)
  var luckRates = newSeq[float](dayCount)
  var shareRates = newSeq[float](dayCount)
  var dayCoordinates = newSeq[float](dayCount)
  for dayIndex in 0 ..< dayCount:
    moneRates[dayIndex] = nextReal(inputData, scanPos)
    luckRates[dayIndex] = nextReal(inputData, scanPos)
    shareRates[dayIndex] = nextReal(inputData, scanPos)
    if luckRates[dayIndex] > 0.0:
      dayCoordinates[dayIndex] = moneRates[dayIndex] / luckRates[dayIndex]
    else:
      dayCoordinates[dayIndex] = 1e100
  var sortedCoordinates = newSeq[float](dayCount)
  for dayIndex in 0 ..< dayCount:
    sortedCoordinates[dayIndex] = dayCoordinates[dayIndex]
  sortedCoordinates.sort(compareFloat)
  var uniqueCoordinates: seq[float] = @[]
  for coordinate in sortedCoordinates:
    if uniqueCoordinates.len == 0 or coordinate != uniqueCoordinates[uniqueCoordinates.len - 1]:
      uniqueCoordinates.add coordinate
  var coordinateIndexes = newSeq[int](dayCount)
  for dayIndex in 0 ..< dayCount:
    coordinateIndexes[dayIndex] = findCoordinate(uniqueCoordinates, dayCoordinates[dayIndex])
  var hullTree = newSeq[HullLine](uniqueCoordinates.len * 4 + 4)
  var bestCapital = startingCapital
  var highestSlope = missingValue
  for dayIndex in 0 ..< dayCount:
    let moneRate = moneRates[dayIndex]
    let luckRate = luckRates[dayIndex]
    var candidateCapital = bestCapital
    if luckRate > 0.0:
      let hullValue = queryHull(hullTree, uniqueCoordinates, 1, 0, uniqueCoordinates.len - 1,
                                coordinateIndexes[dayIndex])
      if hullValue > missingValue * 0.5:
        candidateCapital = max(candidateCapital, hullValue * luckRate)
    elif moneRate > 0.0:
      candidateCapital = max(candidateCapital, highestSlope * moneRate)
    bestCapital = candidateCapital
    let shareRate = shareRates[dayIndex]
    let exchangeValue = moneRate * shareRate + luckRate
    if exchangeValue > 0.0 and bestCapital > 0.0:
      let newSlope = bestCapital * shareRate / exchangeValue
      let newIntercept = bestCapital / exchangeValue
      let newLine = HullLine(slope: newSlope, intercept: newIntercept, present: true)
      insertHullLine(hullTree, uniqueCoordinates, 1, 0, uniqueCoordinates.len - 1, newLine)
      if newSlope > highestSlope:
        highestSlope = newSlope
  appendOutput(formatFloat(bestCapital, ffDecimal, 3))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
