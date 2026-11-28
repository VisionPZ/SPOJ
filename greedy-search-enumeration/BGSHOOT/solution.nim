import algorithm

const flushBlockBytes = 1 shl 17

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

proc compareInts(left, right: int): int =
  if left < right: return -1
  if left > right: return 1
  return 0

proc lowerBound(values: seq[int], target: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = low + (high - low) div 2
    if values[middle] < target:
      low = middle + 1
    else:
      high = middle
  return low

let animalCount = nextInt(inputData, scanPos)
var intervalStarts = newSeq[int](animalCount)
var intervalEnds = newSeq[int](animalCount)
for animalIndex in 0 .. animalCount - 1:
  intervalStarts[animalIndex] = nextInt(inputData, scanPos)
  intervalEnds[animalIndex] = nextInt(inputData, scanPos)

let queryCount = nextInt(inputData, scanPos)
var queryLefts = newSeq[int](queryCount)
var queryRights = newSeq[int](queryCount)
var eventCoords = newSeq[int](0)
for animalIndex in 0 .. animalCount - 1:
  eventCoords.add intervalStarts[animalIndex]
  eventCoords.add intervalEnds[animalIndex] + 1
for queryIndex in 0 .. queryCount - 1:
  queryLefts[queryIndex] = nextInt(inputData, scanPos)
  queryRights[queryIndex] = nextInt(inputData, scanPos)
  eventCoords.add queryLefts[queryIndex]
  eventCoords.add queryRights[queryIndex] + 1

eventCoords.sort(compareInts)
var uniqueCoords = newSeq[int](0)
for coordIndex in 0 .. eventCoords.len - 1:
  if coordIndex == 0 or eventCoords[coordIndex] != eventCoords[coordIndex - 1]:
    uniqueCoords.add eventCoords[coordIndex]

var eventDeltas = newSeq[int](uniqueCoords.len)
for animalIndex in 0 .. animalCount - 1:
  let startIndex = lowerBound(uniqueCoords, intervalStarts[animalIndex])
  let endIndex = lowerBound(uniqueCoords, intervalEnds[animalIndex] + 1)
  eventDeltas[startIndex] += 1
  eventDeltas[endIndex] -= 1

let segmentCount = uniqueCoords.len - 1
var treeBase = 1
while treeBase < segmentCount:
  treeBase = treeBase * 2
var segmentTree = newSeq[int](treeBase * 2)
var runningCoverage = 0
for segmentIndex in 0 .. segmentCount - 1:
  runningCoverage += eventDeltas[segmentIndex]
  segmentTree[treeBase + segmentIndex] = runningCoverage
var buildNode = treeBase - 1
while buildNode >= 1:
  let leftChild = buildNode * 2
  let rightChild = leftChild + 1
  if segmentTree[leftChild] > segmentTree[rightChild]:
    segmentTree[buildNode] = segmentTree[leftChild]
  else:
    segmentTree[buildNode] = segmentTree[rightChild]
  buildNode -= 1

for queryIndex in 0 .. queryCount - 1:
  let leftSegment = lowerBound(uniqueCoords, queryLefts[queryIndex])
  let rightSegment = lowerBound(uniqueCoords, queryRights[queryIndex] + 1) - 1
  var bestCoverage = 0
  var treeLeft = treeBase + leftSegment
  var treeRight = treeBase + rightSegment
  while treeLeft <= treeRight:
    if (treeLeft mod 2) == 1:
      if segmentTree[treeLeft] > bestCoverage:
        bestCoverage = segmentTree[treeLeft]
      treeLeft += 1
    if (treeRight mod 2) == 0:
      if segmentTree[treeRight] > bestCoverage:
        bestCoverage = segmentTree[treeRight]
      treeRight -= 1
    treeLeft = treeLeft div 2
    treeRight = treeRight div 2
  appendOutput($bestCoverage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
