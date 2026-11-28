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

var treeAdjacency = newSeq[seq[int]](0)
var vertexLabels = newSeq[int](0)
var bestLength = 1

proc subsequenceLength(path: seq[int]): int =
  var tails = newSeq[int](0)
  for vertexIndex in path:
    let labelValue = vertexLabels[vertexIndex]
    var lowIndex = 0
    var highIndex = tails.len
    while lowIndex < highIndex:
      let middleIndex = (lowIndex + highIndex) div 2
      if tails[middleIndex] < labelValue:
        lowIndex = middleIndex + 1
      else:
        highIndex = middleIndex
    if lowIndex == tails.len:
      tails.add labelValue
    else:
      tails[lowIndex] = labelValue
  return tails.len

proc explorePaths(currentNode: int, parentNode: int, path: var seq[int]) =
  path.add currentNode
  let currentLength = subsequenceLength(path)
  if currentLength > bestLength:
    bestLength = currentLength
  for neighborNode in treeAdjacency[currentNode]:
    if neighborNode != parentNode:
      explorePaths(neighborNode, currentNode, path)
  path.setLen(path.len - 1)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  treeAdjacency = newSeq[seq[int]](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    treeAdjacency[vertexIndex] = newSeq[int](0)
  for edgeIndex in 0 .. vertexCount - 2:
    let firstVertex = nextInt(inputData, scanPos) - 1
    let secondVertex = nextInt(inputData, scanPos) - 1
    treeAdjacency[firstVertex].add secondVertex
    treeAdjacency[secondVertex].add firstVertex
  vertexLabels = newSeq[int](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    vertexLabels[vertexIndex] = vertexIndex + 1

  bestLength = 1
  var currentPath = newSeq[int](0)
  for startVertex in 0 .. vertexCount - 1:
    explorePaths(startVertex, -1, currentPath)

  appendOutput($bestLength)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
