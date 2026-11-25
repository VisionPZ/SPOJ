const flushBlockBytes = 1 shl 17
const moduloValue = 10243

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

let stationCount = nextInt(inputData, scanPos)
let groupSize = nextInt(inputData, scanPos)
var adjacency = newSeq[seq[int]](stationCount + 1)
for edgeIndex in 0 .. stationCount - 2:
  let endpointOne = nextInt(inputData, scanPos)
  let endpointTwo = nextInt(inputData, scanPos)
  adjacency[endpointOne].add endpointTwo
  adjacency[endpointTwo].add endpointOne

var parentNode = newSeq[int](stationCount + 1)
var traversalOrder = newSeq[int](stationCount)
var stackNodes = newSeq[int](stationCount + 1)
var stackTop = 0
stackNodes[stackTop] = 1
stackTop = 1
parentNode[1] = -1
var orderCount = 0
while stackTop > 0:
  stackTop -= 1
  let currentNode = stackNodes[stackTop]
  traversalOrder[orderCount] = currentNode
  orderCount += 1
  for neighborNode in adjacency[currentNode]:
    if neighborNode != parentNode[currentNode]:
      parentNode[neighborNode] = currentNode
      stackNodes[stackTop] = neighborNode
      stackTop += 1

var combinationCounts = newSeq[int]((stationCount + 1) * (groupSize + 1))
var updatedCounts = newSeq[int](groupSize + 1)
var totalGroups: int64 = 0
for orderIndex in 0 .. orderCount - 1:
  let currentNode = traversalOrder[orderCount - 1 - orderIndex]
  let baseIndex = currentNode * (groupSize + 1)
  combinationCounts[baseIndex + 1] = 1
  for neighborNode in adjacency[currentNode]:
    if parentNode[neighborNode] == currentNode:
      let childIndex = neighborNode * (groupSize + 1)
      for sizeIndex in 0 .. groupSize:
        updatedCounts[sizeIndex] = 0
      for usedCount in 1 .. groupSize:
        let currentWays = combinationCounts[baseIndex + usedCount]
        if currentWays == 0:
          continue
        for extraCount in 0 .. groupSize - usedCount:
          let childWays = if extraCount == 0: 1 else: combinationCounts[childIndex + extraCount]
          if childWays == 0:
            continue
          let targetIndex = usedCount + extraCount
          updatedCounts[targetIndex] = (updatedCounts[targetIndex] + currentWays * childWays) mod moduloValue
      for sizeIndex in 0 .. groupSize:
        combinationCounts[baseIndex + sizeIndex] = updatedCounts[sizeIndex]
  totalGroups = (totalGroups + int64(combinationCounts[baseIndex + groupSize])) mod moduloValue

appendOutput($totalGroups)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
