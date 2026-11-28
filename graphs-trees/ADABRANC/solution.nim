const flushBlockBytes = 1 shl 17
const maxCapacity = 100000

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

proc hasNextNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc findRoot(parent: var seq[int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

proc unionComponents(parent: var seq[int], componentSize: var seq[int], firstNode: int, secondNode: int) =
  var firstRoot = findRoot(parent, firstNode)
  var secondRoot = findRoot(parent, secondNode)
  if firstRoot == secondRoot:
    return
  if componentSize[firstRoot] > componentSize[secondRoot]:
    swap firstRoot, secondRoot
  parent[firstRoot] = secondRoot
  componentSize[secondRoot] = componentSize[secondRoot] + componentSize[firstRoot]

while hasNextNumber(inputData, scanPos):
  let nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var parent = newSeq[int](nodeCount)
  var componentSize = newSeq[int](nodeCount)
  for node in 0 .. nodeCount - 1:
    parent[node] = node
    componentSize[node] = 1
  var edgeHead = newSeq[int](maxCapacity + 1)
  var edgeNext = newSeq[int](edgeCount)
  var edgeFrom = newSeq[int](edgeCount)
  var edgeTo = newSeq[int](edgeCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let fromNode = nextInt(inputData, scanPos)
    let toNode = nextInt(inputData, scanPos)
    let capacity = nextInt(inputData, scanPos)
    edgeFrom[edgeIndex] = fromNode
    edgeTo[edgeIndex] = toNode
    edgeNext[edgeIndex] = edgeHead[capacity]
    edgeHead[capacity] = edgeIndex + 1
  var queryHead = newSeq[int](maxCapacity + 1)
  var queryNext = newSeq[int](queryCount)
  var queryStart = newSeq[int](queryCount)
  for queryIndex in 0 .. queryCount - 1:
    let startNode = nextInt(inputData, scanPos)
    let weight = nextInt(inputData, scanPos)
    queryStart[queryIndex] = startNode
    queryNext[queryIndex] = queryHead[weight]
    queryHead[weight] = queryIndex + 1
  var queryAnswer = newSeq[int](queryCount)
  var capacity = maxCapacity
  while capacity >= 1:
    var edgeLink = edgeHead[capacity]
    while edgeLink != 0:
      let edgeIndex = edgeLink - 1
      unionComponents(parent, componentSize, edgeFrom[edgeIndex], edgeTo[edgeIndex])
      edgeLink = edgeNext[edgeIndex]
    var queryLink = queryHead[capacity]
    while queryLink != 0:
      let queryIndex = queryLink - 1
      queryAnswer[queryIndex] = componentSize[findRoot(parent, queryStart[queryIndex])]
      queryLink = queryNext[queryIndex]
    capacity -= 1
  for queryIndex in 0 .. queryCount - 1:
    appendOutput($queryAnswer[queryIndex])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
