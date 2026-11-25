const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var parsedValue = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return parsedValue

proc minimumTreeLength(buildingCount, streetCount: int, inputData: string, scanPos: var int): int64 =
  var firstEdge = newSeq[int](buildingCount + 1)
  for buildingIndex in 1..buildingCount:
    firstEdge[buildingIndex] = -1
  var edgeTarget = newSeq[int](2 * streetCount)
  var edgeWeight = newSeq[int](2 * streetCount)
  var edgeLink = newSeq[int](2 * streetCount)
  var edgeIndex = 0
  for streetIndex in 0..<streetCount:
    let fromBuilding = nextInt(inputData, scanPos)
    let toBuilding = nextInt(inputData, scanPos)
    let streetLength = nextInt(inputData, scanPos)
    edgeTarget[edgeIndex] = toBuilding
    edgeWeight[edgeIndex] = streetLength
    edgeLink[edgeIndex] = firstEdge[fromBuilding]
    firstEdge[fromBuilding] = edgeIndex
    edgeIndex += 1
    edgeTarget[edgeIndex] = fromBuilding
    edgeWeight[edgeIndex] = streetLength
    edgeLink[edgeIndex] = firstEdge[toBuilding]
    firstEdge[toBuilding] = edgeIndex
    edgeIndex += 1
  var bestEdge = newSeq[int](buildingCount + 1)
  var inTree = newSeq[bool](buildingCount + 1)
  for buildingIndex in 1..buildingCount:
    bestEdge[buildingIndex] = high(int) div 4
  bestEdge[1] = 0
  var treeLength = 0.int64
  for selectionStep in 0..<buildingCount:
    var chosenBuilding = 0
    var bestLength = high(int) div 4
    for buildingIndex in 1..buildingCount:
      if not inTree[buildingIndex] and bestEdge[buildingIndex] < bestLength:
        bestLength = bestEdge[buildingIndex]
        chosenBuilding = buildingIndex
    if chosenBuilding == 0: break
    inTree[chosenBuilding] = true
    treeLength += bestLength.int64
    var edgeCursor = firstEdge[chosenBuilding]
    while edgeCursor != -1:
      let neighborBuilding = edgeTarget[edgeCursor]
      if not inTree[neighborBuilding] and edgeWeight[edgeCursor] < bestEdge[neighborBuilding]:
        bestEdge[neighborBuilding] = edgeWeight[edgeCursor]
      edgeCursor = edgeLink[edgeCursor]
  return treeLength

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let pavingPrice = nextInt(inputData, scanPos).int64
  let buildingCount = nextInt(inputData, scanPos)
  let streetCount = nextInt(inputData, scanPos)
  let treeLength = minimumTreeLength(buildingCount, streetCount, inputData, scanPos)
  appendOutput($(pavingPrice * treeLength))
  outputBuffer.add "\n"

stdout.write outputBuffer
outputBuffer.setLen 0
