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

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] >= '0' and data[checkPos] <= '9':
      return true
    checkPos += 1
  return false

type Road = tuple[to: int, length: int]

var pathKeys = newSeq[int64](0)
var pathNodes = newSeq[int](0)

proc pathLess(leftIndex: int, rightIndex: int): bool =
  if pathKeys[leftIndex] < pathKeys[rightIndex]:
    return true
  if pathKeys[leftIndex] > pathKeys[rightIndex]:
    return false
  return pathNodes[leftIndex] < pathNodes[rightIndex]

proc swapPath(leftIndex: int, rightIndex: int) =
  let savedKey = pathKeys[leftIndex]
  let savedNode = pathNodes[leftIndex]
  pathKeys[leftIndex] = pathKeys[rightIndex]
  pathNodes[leftIndex] = pathNodes[rightIndex]
  pathKeys[rightIndex] = savedKey
  pathNodes[rightIndex] = savedNode

proc siftUpPath(startIndex: int) =
  var childIndex = startIndex
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if pathLess(childIndex, parentIndex):
      swapPath(childIndex, parentIndex)
      childIndex = parentIndex
    else:
      break

proc siftDownPath(startIndex: int) =
  var parentIndex = startIndex
  while true:
    let leftIndex = parentIndex * 2 + 1
    if leftIndex >= pathKeys.len:
      break
    let rightIndex = leftIndex + 1
    var smallestIndex = leftIndex
    if rightIndex < pathKeys.len and pathLess(rightIndex, leftIndex):
      smallestIndex = rightIndex
    if pathLess(smallestIndex, parentIndex):
      swapPath(parentIndex, smallestIndex)
      parentIndex = smallestIndex
    else:
      break

proc pushPath(key: int64, nodeIndex: int) =
  pathKeys.add key
  pathNodes.add nodeIndex
  siftUpPath(pathKeys.len - 1)

proc popPath(key: var int64, nodeIndex: var int) =
  key = pathKeys[0]
  nodeIndex = pathNodes[0]
  let lastIndex = pathKeys.len - 1
  pathKeys[0] = pathKeys[lastIndex]
  pathNodes[0] = pathNodes[lastIndex]
  pathKeys.setLen(lastIndex)
  pathNodes.setLen(lastIndex)
  if pathKeys.len > 0:
    siftDownPath(0)

proc shortestFromSource(graph: seq[seq[Road]], source: int): seq[int64] =
  let nodeCount = graph.len
  var distances = newSeq[int64](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    distances[nodeIndex] = high(int64) div 4
  pathKeys.setLen(0)
  pathNodes.setLen(0)
  distances[source] = 0
  pushPath(0, source)
  while pathKeys.len > 0:
    var key: int64 = 0
    var nodeIndex = 0
    popPath(key, nodeIndex)
    if key != distances[nodeIndex]:
      continue
    for road in graph[nodeIndex]:
      let candidate = key + int64(road.length)
      if candidate < distances[road.to]:
        distances[road.to] = candidate
        pushPath(candidate, road.to)
  return distances

proc sortCosts(costs: var seq[int64]) =
  for index in 1 .. costs.len - 1:
    let key = costs[index]
    var previousIndex = index - 1
    while previousIndex >= 0 and costs[previousIndex] > key:
      costs[previousIndex + 1] = costs[previousIndex]
      previousIndex -= 1
    costs[previousIndex + 1] = key

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasNextToken(inputData, scanPos):
  let nodeCount = nextInt(inputData, scanPos)
  let branchCount = nextInt(inputData, scanPos)
  let groupCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  var graph = newSeq[seq[Road]](nodeCount)
  var reverseGraph = newSeq[seq[Road]](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    graph[nodeIndex] = newSeq[Road](0)
    reverseGraph[nodeIndex] = newSeq[Road](0)
  for roadIndex in 0 .. roadCount - 1:
    let fromNode = nextInt(inputData, scanPos) - 1
    let toNode = nextInt(inputData, scanPos) - 1
    let roadLength = nextInt(inputData, scanPos)
    graph[fromNode].add((toNode, roadLength))
    reverseGraph[toNode].add((fromNode, roadLength))
  let headquarterNode = branchCount
  let distanceFromHQ = shortestFromSource(graph, headquarterNode)
  let distanceToHQ = shortestFromSource(reverseGraph, headquarterNode)
  var costs = newSeq[int64](branchCount)
  for branchIndex in 0 .. branchCount - 1:
    costs[branchIndex] = distanceFromHQ[branchIndex] + distanceToHQ[branchIndex]
  sortCosts(costs)
  var prefixCosts = newSeq[int64](branchCount + 1)
  for branchIndex in 0 .. branchCount - 1:
    prefixCosts[branchIndex + 1] = prefixCosts[branchIndex] + costs[branchIndex]
  var best = newSeq[seq[int64]](groupCount + 1)
  for groupIndex in 0 .. groupCount:
    best[groupIndex] = newSeq[int64](branchCount + 1)
  for branchTotal in 2 .. branchCount:
    best[1][branchTotal] = int64(branchTotal - 1) * prefixCosts[branchTotal]
  for groupTotal in 2 .. groupCount:
    for branchTotal in groupTotal + 1 .. branchCount:
      best[groupTotal][branchTotal] = best[groupTotal - 1][branchTotal - 1]
      let largestGroup = min(branchTotal div groupTotal, branchTotal - groupTotal + 1)
      for groupSize in 2 .. largestGroup:
        let candidate = best[groupTotal - 1][branchTotal - groupSize] +
          int64(groupSize - 1) * (prefixCosts[branchTotal] - prefixCosts[branchTotal - groupSize])
        if candidate < best[groupTotal][branchTotal]:
          best[groupTotal][branchTotal] = candidate
  appendOutput($best[groupCount][branchCount])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
