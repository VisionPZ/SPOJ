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

type
  UpdateEvent = object
    targetNode: int
    oldTeam: int
    newTeam: int
  TreeQuery = object
    startNode: int
    finishNode: int
    rangeLeft: int
    rangeRight: int
    extraNode: int
    timeIndex: int
    answerIndex: int

proc findLca(firstNode: int, secondNode: int, depths: seq[int], ancestorTable: seq[int], logCount: int): int =
  var nodeOne = firstNode
  var nodeTwo = secondNode
  if depths[nodeOne] < depths[nodeTwo]:
    let swapNode = nodeOne
    nodeOne = nodeTwo
    nodeTwo = swapNode
  var depthGap = depths[nodeOne] - depths[nodeTwo]
  for level in 0 .. logCount - 1:
    if (depthGap and (1 shl level)) != 0:
      nodeOne = ancestorTable[nodeOne * logCount + level]
  if nodeOne == nodeTwo:
    return nodeOne
  for levelIndex in 0 .. logCount - 1:
    let level = logCount - 1 - levelIndex
    if ancestorTable[nodeOne * logCount + level] != ancestorTable[nodeTwo * logCount + level]:
      nodeOne = ancestorTable[nodeOne * logCount + level]
      nodeTwo = ancestorTable[nodeTwo * logCount + level]
  return ancestorTable[nodeOne * logCount]

proc comesEarlier(firstQuery: TreeQuery, secondQuery: TreeQuery, blockSize: int): bool =
  let firstLeftBlock = firstQuery.rangeLeft div blockSize
  let secondLeftBlock = secondQuery.rangeLeft div blockSize
  if firstLeftBlock != secondLeftBlock:
    return firstLeftBlock < secondLeftBlock
  let firstRightBlock = firstQuery.rangeRight div blockSize
  let secondRightBlock = secondQuery.rangeRight div blockSize
  if firstRightBlock != secondRightBlock:
    return firstRightBlock < secondRightBlock
  return firstQuery.timeIndex < secondQuery.timeIndex

proc sortQueries(queryList: var seq[TreeQuery], lowIndex: int, highIndex: int, blockSize: int) =
  if lowIndex >= highIndex:
    return
  let pivotQuery = queryList[(lowIndex + highIndex) div 2]
  var leftIndex = lowIndex
  var rightIndex = highIndex
  while leftIndex <= rightIndex:
    while comesEarlier(queryList[leftIndex], pivotQuery, blockSize):
      leftIndex += 1
    while comesEarlier(pivotQuery, queryList[rightIndex], blockSize):
      rightIndex -= 1
    if leftIndex <= rightIndex:
      let swapQuery = queryList[leftIndex]
      queryList[leftIndex] = queryList[rightIndex]
      queryList[rightIndex] = swapQuery
      leftIndex += 1
      rightIndex -= 1
  if lowIndex < rightIndex:
    sortQueries(queryList, lowIndex, rightIndex, blockSize)
  if leftIndex < highIndex:
    sortQueries(queryList, leftIndex, highIndex, blockSize)

proc addTeam(teamIndex: int, teamCounts: var seq[int], happiness: var int64) =
  happiness = happiness + int64(teamCounts[teamIndex])
  teamCounts[teamIndex] = teamCounts[teamIndex] + 1

proc removeTeam(teamIndex: int, teamCounts: var seq[int], happiness: var int64) =
  teamCounts[teamIndex] = teamCounts[teamIndex] - 1
  happiness = happiness - int64(teamCounts[teamIndex])

proc toggleTourNode(nodeIndex: int, workingTeams: seq[int], activeNodes: var seq[bool], teamCounts: var seq[int], happiness: var int64) =
  let teamIndex = workingTeams[nodeIndex]
  if activeNodes[nodeIndex]:
    removeTeam(teamIndex, teamCounts, happiness)
    activeNodes[nodeIndex] = false
  else:
    addTeam(teamIndex, teamCounts, happiness)
    activeNodes[nodeIndex] = true

proc applyUpdate(event: UpdateEvent, workingTeams: var seq[int], activeNodes: seq[bool], teamCounts: var seq[int], happiness: var int64) =
  if workingTeams[event.targetNode] != event.newTeam:
    if activeNodes[event.targetNode]:
      removeTeam(workingTeams[event.targetNode], teamCounts, happiness)
    workingTeams[event.targetNode] = event.newTeam
    if activeNodes[event.targetNode]:
      addTeam(event.newTeam, teamCounts, happiness)

proc revertUpdate(event: UpdateEvent, workingTeams: var seq[int], activeNodes: seq[bool], teamCounts: var seq[int], happiness: var int64) =
  if workingTeams[event.targetNode] != event.oldTeam:
    if activeNodes[event.targetNode]:
      removeTeam(workingTeams[event.targetNode], teamCounts, happiness)
    workingTeams[event.targetNode] = event.oldTeam
    if activeNodes[event.targetNode]:
      addTeam(event.oldTeam, teamCounts, happiness)

let friendCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var initialTeams = newSeq[int](friendCount)
var workingTeams = newSeq[int](friendCount)
var maximumTeam = 0
for friendIndex in 0 .. friendCount - 1:
  let teamIndex = nextInt(inputData, scanPos)
  initialTeams[friendIndex] = teamIndex
  workingTeams[friendIndex] = teamIndex
  if teamIndex > maximumTeam:
    maximumTeam = teamIndex

var adjacency = newSeq[seq[int]](friendCount)
for edgeIndex in 0 .. friendCount - 2:
  let endpointOne = nextInt(inputData, scanPos)
  let endpointTwo = nextInt(inputData, scanPos)
  adjacency[endpointOne].add endpointTwo
  adjacency[endpointTwo].add endpointOne

var updateEvents = newSeq[UpdateEvent](queryCount)
var treeQueries = newSeq[TreeQuery](queryCount)
var updateCount = 0
var answerCount = 0
for queryIndex in 0 .. queryCount - 1:
  let queryType = nextInt(inputData, scanPos)
  if queryType == 1:
    let targetNode = nextInt(inputData, scanPos)
    let newTeam = nextInt(inputData, scanPos)
    updateEvents[updateCount].targetNode = targetNode
    updateEvents[updateCount].oldTeam = workingTeams[targetNode]
    updateEvents[updateCount].newTeam = newTeam
    workingTeams[targetNode] = newTeam
    updateCount += 1
    if newTeam > maximumTeam:
      maximumTeam = newTeam
  else:
    treeQueries[answerCount].startNode = nextInt(inputData, scanPos)
    treeQueries[answerCount].finishNode = nextInt(inputData, scanPos)
    treeQueries[answerCount].timeIndex = updateCount
    treeQueries[answerCount].answerIndex = answerCount
    treeQueries[answerCount].extraNode = -1
    answerCount += 1

var logCount = 1
while (1 shl logCount) <= friendCount:
  logCount += 1
var tourPositions = newSeq[int](friendCount)
var exitPositions = newSeq[int](friendCount)
var eulerTour = newSeq[int](2 * friendCount)
var ancestorTable = newSeq[int](friendCount * logCount)
var depths = newSeq[int](friendCount)
var parents = newSeq[int](friendCount)
var stackNodes = newSeq[int](friendCount + 1)
var stackEdges = newSeq[int](friendCount + 1)
var stackTop = 0
stackNodes[stackTop] = 0
stackEdges[stackTop] = 0
stackTop = 1
var tourLength = 0
while stackTop > 0:
  stackTop -= 1
  let currentNode = stackNodes[stackTop]
  let edgeIndex = stackEdges[stackTop]
  if edgeIndex == 0:
    tourPositions[currentNode] = tourLength
    eulerTour[tourLength] = currentNode
    tourLength += 1
  if edgeIndex < adjacency[currentNode].len:
    let neighborNode = adjacency[currentNode][edgeIndex]
    stackNodes[stackTop] = currentNode
    stackEdges[stackTop] = edgeIndex + 1
    stackTop += 1
    if neighborNode != parents[currentNode]:
      parents[neighborNode] = currentNode
      depths[neighborNode] = depths[currentNode] + 1
      ancestorTable[neighborNode * logCount] = currentNode
      for level in 1 .. logCount - 1:
        let halfAncestor = ancestorTable[neighborNode * logCount + level - 1]
        ancestorTable[neighborNode * logCount + level] = ancestorTable[halfAncestor * logCount + level - 1]
      stackNodes[stackTop] = neighborNode
      stackEdges[stackTop] = 0
      stackTop += 1
  else:
    exitPositions[currentNode] = tourLength
    eulerTour[tourLength] = currentNode
    tourLength += 1

for queryIndex in 0 .. answerCount - 1:
  var startNode = treeQueries[queryIndex].startNode
  var finishNode = treeQueries[queryIndex].finishNode
  if tourPositions[startNode] > tourPositions[finishNode]:
    let swapNode = startNode
    startNode = finishNode
    finishNode = swapNode
  let commonNode = findLca(startNode, finishNode, depths, ancestorTable, logCount)
  if commonNode == startNode:
    treeQueries[queryIndex].rangeLeft = tourPositions[startNode]
    treeQueries[queryIndex].rangeRight = tourPositions[finishNode]
  else:
    treeQueries[queryIndex].rangeLeft = exitPositions[startNode]
    treeQueries[queryIndex].rangeRight = tourPositions[finishNode]
    treeQueries[queryIndex].extraNode = commonNode

let blockSize = friendCount div 32 + 1
sortQueries(treeQueries, 0, answerCount - 1, blockSize)

var activeNodes = newSeq[bool](friendCount)
var teamCounts = newSeq[int](maximumTeam + 2)
var happiness: int64 = 0
for friendIndex in 0 .. friendCount - 1:
  workingTeams[friendIndex] = initialTeams[friendIndex]
var answers = newSeq[int64](answerCount)
var currentTime = 0
var currentLeft = 0
var currentRight = -1

for queryIndex in 0 .. answerCount - 1:
  let currentQuery = treeQueries[queryIndex]
  while currentTime < currentQuery.timeIndex:
    applyUpdate(updateEvents[currentTime], workingTeams, activeNodes, teamCounts, happiness)
    currentTime += 1
  while currentTime > currentQuery.timeIndex:
    currentTime -= 1
    revertUpdate(updateEvents[currentTime], workingTeams, activeNodes, teamCounts, happiness)
  while currentLeft > currentQuery.rangeLeft:
    currentLeft -= 1
    toggleTourNode(eulerTour[currentLeft], workingTeams, activeNodes, teamCounts, happiness)
  while currentRight < currentQuery.rangeRight:
    currentRight += 1
    toggleTourNode(eulerTour[currentRight], workingTeams, activeNodes, teamCounts, happiness)
  while currentLeft < currentQuery.rangeLeft:
    toggleTourNode(eulerTour[currentLeft], workingTeams, activeNodes, teamCounts, happiness)
    currentLeft += 1
  while currentRight > currentQuery.rangeRight:
    toggleTourNode(eulerTour[currentRight], workingTeams, activeNodes, teamCounts, happiness)
    currentRight -= 1
  if currentQuery.extraNode >= 0:
    toggleTourNode(currentQuery.extraNode, workingTeams, activeNodes, teamCounts, happiness)
    answers[currentQuery.answerIndex] = happiness
    toggleTourNode(currentQuery.extraNode, workingTeams, activeNodes, teamCounts, happiness)
  else:
    answers[currentQuery.answerIndex] = happiness

for answerValue in answers:
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
