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

proc farthestWalk(nodeCount: int, head: seq[int], neighborNode: seq[int], nextEdge: seq[int], edgeWeight: seq[int64], startNode: int, distances: var seq[int64]): int =
  for nodeIndex in 0 .. nodeCount:
    distances[nodeIndex] = -1
  var walkStack = newSeq[int](nodeCount + 1)
  var stackTop = 0
  walkStack[0] = startNode
  distances[startNode] = 0
  var farthestNode = startNode
  while stackTop >= 0:
    let currentNode = walkStack[stackTop]
    stackTop -= 1
    if distances[currentNode] > distances[farthestNode]:
      farthestNode = currentNode
    var edgeIndex = head[currentNode]
    while edgeIndex != -1:
      let neighbor = neighborNode[edgeIndex]
      if distances[neighbor] < 0:
        distances[neighbor] = distances[currentNode] + edgeWeight[edgeIndex]
        stackTop += 1
        walkStack[stackTop] = neighbor
      edgeIndex = nextEdge[edgeIndex]
  return farthestNode

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let nodeCount = nextInt(inputData, scanPos)
  var head = newSeq[int](nodeCount + 1)
  for nodeIndex in 0 .. nodeCount:
    head[nodeIndex] = -1
  let edgeSlots = 2 * (nodeCount - 1)
  var neighborNode = newSeq[int](edgeSlots)
  var nextEdge = newSeq[int](edgeSlots)
  var edgeWeight = newSeq[int64](edgeSlots)
  var edgeIndex = 0
  for edgeNumber in 0 .. nodeCount - 2:
    let firstNode = nextInt(inputData, scanPos)
    let secondNode = nextInt(inputData, scanPos)
    let dogCount = int64(nextInt(inputData, scanPos))
    neighborNode[edgeIndex] = secondNode
    edgeWeight[edgeIndex] = dogCount
    nextEdge[edgeIndex] = head[firstNode]
    head[firstNode] = edgeIndex
    edgeIndex += 1
    neighborNode[edgeIndex] = firstNode
    edgeWeight[edgeIndex] = dogCount
    nextEdge[edgeIndex] = head[secondNode]
    head[secondNode] = edgeIndex
    edgeIndex += 1
  var fromStart = newSeq[int64](nodeCount + 1)
  var fromFirstEnd = newSeq[int64](nodeCount + 1)
  var fromSecondEnd = newSeq[int64](nodeCount + 1)
  let firstEnd = farthestWalk(nodeCount, head, neighborNode, nextEdge, edgeWeight, 1, fromStart)
  let secondEnd = farthestWalk(nodeCount, head, neighborNode, nextEdge, edgeWeight, firstEnd, fromFirstEnd)
  discard farthestWalk(nodeCount, head, neighborNode, nextEdge, edgeWeight, secondEnd, fromSecondEnd)
  for nodeIndex in 1 .. nodeCount:
    if nodeIndex > 1:
      appendOutput(" ")
    appendOutput($(max(fromFirstEnd[nodeIndex], fromSecondEnd[nodeIndex])))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
