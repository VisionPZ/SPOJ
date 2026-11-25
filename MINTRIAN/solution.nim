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

proc isChordal(vertexCount: int, edgeCount: int, scanPosition: var int): bool =
  var adjacency = newSeq[bool](vertexCount * vertexCount)
  var neighborList = newSeq[seq[int]](vertexCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let firstVertex = nextInt(inputData, scanPosition)
    let secondVertex = nextInt(inputData, scanPosition)
    if firstVertex == secondVertex:
      continue
    let forwardIndex = firstVertex * vertexCount + secondVertex
    let backwardIndex = secondVertex * vertexCount + firstVertex
    if not adjacency[forwardIndex]:
      adjacency[forwardIndex] = true
      adjacency[backwardIndex] = true
      neighborList[firstVertex].add secondVertex
      neighborList[secondVertex].add firstVertex

  var neighborMarks = newSeq[int](vertexCount)
  var chosen = newSeq[bool](vertexCount)
  var eliminationOrder = newSeq[int](vertexCount)
  for stepIndex in 0 .. vertexCount - 1:
    var bestVertex = -1
    var bestMark = -1
    for vertexIndex in 0 .. vertexCount - 1:
      if not chosen[vertexIndex] and neighborMarks[vertexIndex] > bestMark:
        bestVertex = vertexIndex
        bestMark = neighborMarks[vertexIndex]
    chosen[bestVertex] = true
    eliminationOrder[stepIndex] = bestVertex
    for neighborIndex in neighborList[bestVertex]:
      if not chosen[neighborIndex]:
        neighborMarks[neighborIndex] += 1

  var rankInOrder = newSeq[int](vertexCount)
  for stepIndex in 0 .. vertexCount - 1:
    rankInOrder[eliminationOrder[stepIndex]] = stepIndex

  for stepIndex in 0 .. vertexCount - 1:
    let currentVertex = eliminationOrder[stepIndex]
    var anchorVertex = -1
    for neighborIndex in neighborList[currentVertex]:
      if rankInOrder[neighborIndex] < stepIndex:
        anchorVertex = neighborIndex
        break
    if anchorVertex < 0:
      continue
    for neighborIndex in neighborList[currentVertex]:
      if rankInOrder[neighborIndex] < stepIndex and neighborIndex != anchorVertex:
        if not adjacency[anchorVertex * vertexCount + neighborIndex]:
          return false
  return true

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  if isChordal(vertexCount, edgeCount, scanPos):
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
