const flushBlockBytes = 1 shl 17
const maxVertexIndex = 300

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var groupParent = newSeq[int](maxVertexIndex + 1)
var vertexDegrees = newSeq[int](maxVertexIndex + 1)

proc findGroup(vertexHere: int): int =
  var walkVertex = vertexHere
  while groupParent[walkVertex] != walkVertex:
    groupParent[walkVertex] = groupParent[groupParent[walkVertex]]
    walkVertex = groupParent[walkVertex]
  return walkVertex

proc joinGroups(firstVertex: int, secondVertex: int) =
  let firstRoot = findGroup(firstVertex)
  let secondRoot = findGroup(secondVertex)
  if firstRoot != secondRoot:
    groupParent[secondRoot] = firstRoot

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let startVertex = nextInt(inputData, scanPos)
  for vertexIndex in 0 .. maxVertexIndex:
    groupParent[vertexIndex] = vertexIndex
    vertexDegrees[vertexIndex] = 0
  var edgeTotal = 0
  while true:
    let edgeStart = nextInt(inputData, scanPos)
    let edgeEnd = nextInt(inputData, scanPos)
    if edgeStart == -1 and edgeEnd == -1:
      break
    vertexDegrees[edgeStart] += 1
    vertexDegrees[edgeEnd] += 1
    joinGroups(edgeStart, edgeEnd)
    edgeTotal += 1

  var drawable = true
  if edgeTotal > 0 and vertexDegrees[startVertex] == 0:
    drawable = false
  if drawable:
    for vertexIndex in 1 .. maxVertexIndex:
      if vertexDegrees[vertexIndex] > 0:
        if vertexDegrees[vertexIndex] mod 2 != 0:
          drawable = false
          break
        if findGroup(vertexIndex) != findGroup(startVertex):
          drawable = false
          break
  if drawable:
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
