const flushBlockBytes = 1 shl 17
const maxLevel = 18

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

while true:
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let cityCount = nextInt(inputData, scanPos)
  if cityCount == 0:
    break
  let edgeCapacity = 2 * (cityCount - 1)
  var headEdge = newSeq[int](cityCount + 1)
  for index in 0 .. cityCount:
    headEdge[index] = -1
  var edgeTarget = newSeq[int](edgeCapacity)
  var edgeNext = newSeq[int](edgeCapacity)
  var edgeCost = newSeq[int](edgeCapacity)
  var edgeCursor = 0
  for roadIndex in 0 .. cityCount - 2:
    let cityA = nextInt(inputData, scanPos)
    let cityB = nextInt(inputData, scanPos)
    let ticketCost = nextInt(inputData, scanPos)
    edgeTarget[edgeCursor] = cityB
    edgeCost[edgeCursor] = ticketCost
    edgeNext[edgeCursor] = headEdge[cityA]
    headEdge[cityA] = edgeCursor
    edgeCursor += 1
    edgeTarget[edgeCursor] = cityA
    edgeCost[edgeCursor] = ticketCost
    edgeNext[edgeCursor] = headEdge[cityB]
    headEdge[cityB] = edgeCursor
    edgeCursor += 1
  var depth = newSeq[int](cityCount + 1)
  var traversalStack = newSeq[int](cityCount)
  var stackSize = 1
  traversalStack[0] = 1
  var ancestor = newSeq[int]((cityCount + 1) * maxLevel)
  var maxEdgeCost = newSeq[int]((cityCount + 1) * maxLevel)
  ancestor[1 * maxLevel] = 0
  maxEdgeCost[1 * maxLevel] = 0
  while stackSize > 0:
    stackSize -= 1
    let currentCity = traversalStack[stackSize]
    var edgeIndex = headEdge[currentCity]
    while edgeIndex != -1:
      let neighborCity = edgeTarget[edgeIndex]
      if neighborCity != ancestor[currentCity * maxLevel]:
        ancestor[neighborCity * maxLevel] = currentCity
        maxEdgeCost[neighborCity * maxLevel] = edgeCost[edgeIndex]
        depth[neighborCity] = depth[currentCity] + 1
        traversalStack[stackSize] = neighborCity
        stackSize += 1
      edgeIndex = edgeNext[edgeIndex]
  for levelIndex in 1 .. maxLevel - 1:
    for cityIndex in 1 .. cityCount:
      let middleCity = ancestor[cityIndex * maxLevel + levelIndex - 1]
      ancestor[cityIndex * maxLevel + levelIndex] = ancestor[middleCity * maxLevel + levelIndex - 1]
      if maxEdgeCost[middleCity * maxLevel + levelIndex - 1] > maxEdgeCost[cityIndex * maxLevel + levelIndex - 1]:
        maxEdgeCost[cityIndex * maxLevel + levelIndex] = maxEdgeCost[middleCity * maxLevel + levelIndex - 1]
      else:
        maxEdgeCost[cityIndex * maxLevel + levelIndex] = maxEdgeCost[cityIndex * maxLevel + levelIndex - 1]
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    var cityA = nextInt(inputData, scanPos)
    var cityB = nextInt(inputData, scanPos)
    var answer = 0
    if depth[cityA] < depth[cityB]:
      swap cityA, cityB
    let depthGap = depth[cityA] - depth[cityB]
    for levelIndex in 0 .. maxLevel - 1:
      if (depthGap and (1 shl levelIndex)) != 0:
        let tableIndex = cityA * maxLevel + levelIndex
        if maxEdgeCost[tableIndex] > answer:
          answer = maxEdgeCost[tableIndex]
        cityA = ancestor[tableIndex]
    if cityA != cityB:
      for levelIndex in countdown(maxLevel - 1, 0):
        let tableA = cityA * maxLevel + levelIndex
        let tableB = cityB * maxLevel + levelIndex
        if ancestor[tableA] != ancestor[tableB]:
          if maxEdgeCost[tableA] > answer:
            answer = maxEdgeCost[tableA]
          if maxEdgeCost[tableB] > answer:
            answer = maxEdgeCost[tableB]
          cityA = ancestor[tableA]
          cityB = ancestor[tableB]
      if maxEdgeCost[cityA * maxLevel] > answer:
        answer = maxEdgeCost[cityA * maxLevel]
      if maxEdgeCost[cityB * maxLevel] > answer:
        answer = maxEdgeCost[cityB * maxLevel]
    appendOutput($answer)
    appendOutput("\n")
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
