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

let nodeCount = nextInt(inputData, scanPos)
let startNode = nextInt(inputData, scanPos)
let targetNode = nextInt(inputData, scanPos)
let edgeCapacity = 2 * (nodeCount - 1)
var head = newSeq[int](nodeCount + 1)
for nodeIndex in 0 .. nodeCount:
  head[nodeIndex] = -1
var target = newSeq[int](edgeCapacity)
var weight = newSeq[int64](edgeCapacity)
var nextEdge = newSeq[int](edgeCapacity)
var edgeIndex = 0
for roadIndex in 0 .. nodeCount - 2:
  let firstNode = nextInt(inputData, scanPos)
  let secondNode = nextInt(inputData, scanPos)
  let roadTime = int64(nextInt(inputData, scanPos))
  target[edgeIndex] = secondNode
  weight[edgeIndex] = roadTime
  nextEdge[edgeIndex] = head[firstNode]
  head[firstNode] = edgeIndex
  edgeIndex += 1
  target[edgeIndex] = firstNode
  weight[edgeIndex] = roadTime
  nextEdge[edgeIndex] = head[secondNode]
  head[secondNode] = edgeIndex
  edgeIndex += 1
var distances = newSeq[int64](nodeCount + 1)
for nodeIndex in 0 .. nodeCount:
  distances[nodeIndex] = -1
var queue = newSeq[int](nodeCount + 1)
var queueStart = 0
var queueEnd = 0
queue[queueEnd] = startNode
queueEnd += 1
distances[startNode] = 0
while queueStart < queueEnd and queue[queueStart] != targetNode:
  let currentNode = queue[queueStart]
  queueStart += 1
  var currentEdge = head[currentNode]
  while currentEdge != -1:
    let neighbour = target[currentEdge]
    if distances[neighbour] == -1:
      distances[neighbour] = distances[currentNode] + weight[currentEdge]
      queue[queueEnd] = neighbour
      queueEnd += 1
    currentEdge = nextEdge[currentEdge]
appendOutput($distances[targetNode])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
