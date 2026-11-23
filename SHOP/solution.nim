import sequtils

const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const maxGridCells = 25 * 25
const maxStepCost = 9
const bucketTotal = maxGridCells * maxStepCost + 2
const nodeCapacity = maxGridCells * 4 + 32
const unreachableCost = 1000000000

var inputData: string
var inputLine: string
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc skipWhitespace() =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos = scanPos + 1

proc readInteger(): int =
  skipWhitespace()
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + (int(inputData[scanPos]) - firstDigitValue)
    scanPos = scanPos + 1
  return value

var gridCells: seq[char]
var distanceValue: seq[int]
var bucketHead = repeat(-1, bucketTotal)
var bucketVertex = newSeq[int](nodeCapacity)
var bucketNext = newSeq[int](nodeCapacity)
var touchedBuckets: seq[int]
var nodeTotal = 0

proc enqueueNode(distanceIndex: int, cellIndex: int) =
  if distanceIndex >= bucketTotal or nodeTotal >= nodeCapacity:
    return
  if bucketHead[distanceIndex] == -1:
    touchedBuckets.add distanceIndex
  bucketNext[nodeTotal] = bucketHead[distanceIndex]
  bucketHead[distanceIndex] = nodeTotal
  bucketVertex[nodeTotal] = cellIndex
  nodeTotal = nodeTotal + 1

proc resetBuckets() =
  for distanceIndex in touchedBuckets:
    bucketHead[distanceIndex] = -1
  touchedBuckets.setLen 0

proc tryRelax(neighborCell: int, currentDistance: int) =
  let cellChar = gridCells[neighborCell]
  if cellChar == 'X':
    return
  var stepCost = 0
  if cellChar >= '1' and cellChar <= '9':
    stepCost = int(cellChar) - firstDigitValue
  let candidateDistance = currentDistance + stepCost
  if candidateDistance < distanceValue[neighborCell]:
    distanceValue[neighborCell] = candidateDistance
    enqueueNode(candidateDistance, neighborCell)

proc shortestPathCost(width: int, height: int, startCell: int, targetCell: int): int =
  let cellCount = width * height
  distanceValue.setLen(cellCount)
  for cellIndex in 0 .. cellCount - 1:
    distanceValue[cellIndex] = unreachableCost
  nodeTotal = 0
  resetBuckets()
  distanceValue[startCell] = 0
  enqueueNode(0, startCell)
  var currentDistance = 0
  while true:
    while true:
      let nodeIndex = bucketHead[currentDistance]
      if nodeIndex < 0:
        break
      bucketHead[currentDistance] = bucketNext[nodeIndex]
      let settledCell = bucketVertex[nodeIndex]
      if distanceValue[settledCell] != currentDistance:
        continue
      if settledCell == targetCell:
        return currentDistance
      let row = settledCell div width
      let col = settledCell mod width
      if row > 0:
        tryRelax(settledCell - width, currentDistance)
      if row < height - 1:
        tryRelax(settledCell + width, currentDistance)
      if col > 0:
        tryRelax(settledCell - 1, currentDistance)
      if col < width - 1:
        tryRelax(settledCell + 1, currentDistance)
    currentDistance = currentDistance + 1
    while currentDistance < bucketTotal and bucketHead[currentDistance] == -1:
      currentDistance = currentDistance + 1
    if currentDistance >= bucketTotal:
      return unreachableCost

var outputBuffer: string
var width = readInteger()
var height = readInteger()
while width != 0 or height != 0:
  let cellCount = width * height
  gridCells.setLen(cellCount)
  var startCell = -1
  var targetCell = -1
  for row in 0 .. height - 1:
    let rowStart = row * width
    skipWhitespace()
    for col in 0 .. width - 1:
      let cellChar = inputData[scanPos]
      scanPos = scanPos + 1
      gridCells[rowStart + col] = cellChar
      if cellChar == 'S':
        startCell = rowStart + col
      if cellChar == 'D':
        targetCell = rowStart + col
  let answer = shortestPathCost(width, height, startCell, targetCell)
  outputBuffer.add $answer
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  width = readInteger()
  height = readInteger()
stdout.write outputBuffer
