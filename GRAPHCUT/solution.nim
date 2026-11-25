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

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 0 .. caseCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  let cutEdgeCount = nextInt(inputData, scanPos)
  var adjacencyHead = newSeq[int](vertexCount + 1)
  var edgeTarget = newSeq[int](2 * edgeCount + 1)
  var edgeNext = newSeq[int](2 * edgeCount + 1)
  var edgeMark = newSeq[int](2 * edgeCount + 1)
  for edgeIndex in 1 .. edgeCount:
    let fromVertex = nextInt(inputData, scanPos)
    let toVertex = nextInt(inputData, scanPos)
    edgeTarget[edgeIndex] = toVertex
    edgeMark[edgeIndex] = 0
    if edgeIndex <= cutEdgeCount:
      edgeMark[edgeIndex] = 1
    edgeNext[edgeIndex] = adjacencyHead[fromVertex]
    adjacencyHead[fromVertex] = edgeIndex
    edgeTarget[edgeIndex + edgeCount] = fromVertex
    edgeNext[edgeIndex + edgeCount] = adjacencyHead[toVertex]
    adjacencyHead[toVertex] = edgeIndex + edgeCount
    edgeMark[edgeIndex + edgeCount] = edgeMark[edgeIndex]
  var vertexSide = newSeq[int](vertexCount + 1)
  for vertexIndex in 1 .. vertexCount:
    vertexSide[vertexIndex] = -1
  var queue = newSeq[int](vertexCount)
  var isCut = true
  for rootVertex in 1 .. vertexCount:
    if vertexSide[rootVertex] != -1:
      continue
    vertexSide[rootVertex] = 0
    var queueHead = 0
    var queueTail = 0
    queue[queueTail] = rootVertex
    queueTail += 1
    while queueHead < queueTail:
      let currentVertex = queue[queueHead]
      queueHead += 1
      var edgeCursor = adjacencyHead[currentVertex]
      while edgeCursor != 0:
        let neighborVertex = edgeTarget[edgeCursor]
        let wantedSide = vertexSide[currentVertex] xor edgeMark[edgeCursor]
        if vertexSide[neighborVertex] == -1:
          vertexSide[neighborVertex] = wantedSide
          queue[queueTail] = neighborVertex
          queueTail += 1
        elif vertexSide[neighborVertex] != wantedSide:
          isCut = false
        edgeCursor = edgeNext[edgeCursor]
  if isCut:
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
