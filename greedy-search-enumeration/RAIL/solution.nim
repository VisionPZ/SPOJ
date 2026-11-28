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

type SimplifiedEdge = object
  firstNode: int
  secondNode: int
  pathCost: int64

proc compareEdges(leftEdge: SimplifiedEdge, rightEdge: SimplifiedEdge): int =
  if leftEdge.firstNode < rightEdge.firstNode:
    return -1
  if leftEdge.firstNode > rightEdge.firstNode:
    return 1
  if leftEdge.secondNode < rightEdge.secondNode:
    return -1
  if leftEdge.secondNode > rightEdge.secondNode:
    return 1
  if leftEdge.pathCost < rightEdge.pathCost:
    return -1
  if leftEdge.pathCost > rightEdge.pathCost:
    return 1
  return 0

proc mergeSortEdges(edgeList: var seq[SimplifiedEdge], helperList: var seq[SimplifiedEdge], leftBound: int, rightBound: int) =
  if rightBound - leftBound <= 1:
    return
  let middleIndex = (leftBound + rightBound) div 2
  mergeSortEdges(edgeList, helperList, leftBound, middleIndex)
  mergeSortEdges(edgeList, helperList, middleIndex, rightBound)
  var leftCursor = leftBound
  var rightCursor = middleIndex
  var writeCursor = leftBound
  while leftCursor < middleIndex and rightCursor < rightBound:
    if compareEdges(edgeList[leftCursor], edgeList[rightCursor]) <= 0:
      helperList[writeCursor] = edgeList[leftCursor]
      leftCursor += 1
    else:
      helperList[writeCursor] = edgeList[rightCursor]
      rightCursor += 1
    writeCursor += 1
  while leftCursor < middleIndex:
    helperList[writeCursor] = edgeList[leftCursor]
    leftCursor += 1
    writeCursor += 1
  while rightCursor < rightBound:
    helperList[writeCursor] = edgeList[rightCursor]
    rightCursor += 1
    writeCursor += 1
  for edgeIndex in leftBound .. rightBound - 1:
    edgeList[edgeIndex] = helperList[edgeIndex]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let stationCount = nextInt(inputData, scanPos)
  let segmentCount = nextInt(inputData, scanPos)
  var headEdges = newSeq[int](stationCount + 1)
  for stationIndex in 1 .. stationCount:
    headEdges[stationIndex] = -1
  var edgeTargets = newSeq[int](2 * segmentCount)
  var edgeNexts = newSeq[int](2 * segmentCount)
  var edgeLengths = newSeq[int](2 * segmentCount)
  var degreeCounts = newSeq[int](stationCount + 1)
  var edgeCursor = 0
  for segmentIndex in 0 .. segmentCount - 1:
    let firstStation = nextInt(inputData, scanPos)
    let secondStation = nextInt(inputData, scanPos)
    let segmentLength = nextInt(inputData, scanPos)
    edgeTargets[edgeCursor] = secondStation
    edgeNexts[edgeCursor] = headEdges[firstStation]
    edgeLengths[edgeCursor] = segmentLength
    headEdges[firstStation] = edgeCursor
    degreeCounts[firstStation] += 1
    edgeCursor += 1
    edgeTargets[edgeCursor] = firstStation
    edgeNexts[edgeCursor] = headEdges[secondStation]
    edgeLengths[edgeCursor] = segmentLength
    headEdges[secondStation] = edgeCursor
    degreeCounts[secondStation] += 1
    edgeCursor += 1
  var resultEdges = newSeq[SimplifiedEdge]()
  for startStation in 1 .. stationCount:
    if degreeCounts[startStation] == 2:
      continue
    var scanEdge = headEdges[startStation]
    while scanEdge != -1:
      let startEdge = scanEdge
      scanEdge = edgeNexts[scanEdge]
      var travelEdge = startEdge
      var nextStation = edgeTargets[travelEdge]
      var accumulatedCost: int64 = int64(edgeLengths[travelEdge])
      while degreeCounts[nextStation] == 2:
        var departureEdge = -1
        var candidateEdge = headEdges[nextStation]
        while candidateEdge != -1:
          if candidateEdge != (travelEdge xor 1):
            departureEdge = candidateEdge
            break
          candidateEdge = edgeNexts[candidateEdge]
        travelEdge = departureEdge
        nextStation = edgeTargets[travelEdge]
        accumulatedCost = accumulatedCost + int64(edgeLengths[travelEdge])
      if startStation < nextStation or (startStation == nextStation and startEdge < travelEdge):
        var simplifiedEdge: SimplifiedEdge
        if startStation <= nextStation:
          simplifiedEdge.firstNode = startStation
          simplifiedEdge.secondNode = nextStation
        else:
          simplifiedEdge.firstNode = nextStation
          simplifiedEdge.secondNode = startStation
        simplifiedEdge.pathCost = accumulatedCost
        resultEdges.add simplifiedEdge
  var helperEdges = newSeq[SimplifiedEdge](resultEdges.len)
  mergeSortEdges(resultEdges, helperEdges, 0, resultEdges.len)
  appendOutput($(resultEdges.len))
  outputBuffer.add '\n'
  for edgeIndex in 0 .. resultEdges.len - 1:
    let simplifiedEdge = resultEdges[edgeIndex]
    appendOutput($(simplifiedEdge.firstNode) & " " & $(simplifiedEdge.secondNode) & " " & $(simplifiedEdge.pathCost))
    outputBuffer.add '\n'
  if caseIndex < caseCount - 1:
    appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
