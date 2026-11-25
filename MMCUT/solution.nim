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

let vertexCount = nextInt(inputData, scanPos)
let commodityCount = nextInt(inputData, scanPos)
let rootVertex = vertexCount - 1

var adjacency = newSeq[seq[int]](vertexCount)
var mustCut = newSeq[bool](vertexCount)

for commodityIndex in 0 .. commodityCount - 1:
  let firstVertex = nextInt(inputData, scanPos)
  let secondVertex = nextInt(inputData, scanPos)
  if firstVertex == rootVertex:
    mustCut[secondVertex] = true
  elif secondVertex == rootVertex:
    mustCut[firstVertex] = true
  else:
    adjacency[firstVertex].add secondVertex
    adjacency[secondVertex].add firstVertex

var vertexColor = newSeq[int](vertexCount)
for vertexIndex in 0 .. vertexCount - 1:
  vertexColor[vertexIndex] = -1

var coloringPossible = true

proc colorComponent(startVertex: int, startColor: int): bool =
  var pending = newSeq[int]()
  pending.add startVertex
  vertexColor[startVertex] = startColor
  while pending.len > 0:
    let currentVertex = pending.pop()
    let wantedColor = 1 - vertexColor[currentVertex]
    for neighborVertex in adjacency[currentVertex]:
      if vertexColor[neighborVertex] == -1:
        vertexColor[neighborVertex] = wantedColor
        pending.add neighborVertex
      elif vertexColor[neighborVertex] != wantedColor:
        return false
  return true

for leafVertex in 0 .. rootVertex - 1:
  if mustCut[leafVertex]:
    if vertexColor[leafVertex] == 0 or not colorComponent(leafVertex, 1):
      coloringPossible = false

if coloringPossible:
  for leafVertex in 0 .. rootVertex - 1:
    if vertexColor[leafVertex] == -1:
      if not colorComponent(leafVertex, 1):
        coloringPossible = false

var answer = 2
if commodityCount == 0:
  answer = 0
elif coloringPossible:
  answer = 1

appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
