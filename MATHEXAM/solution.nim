const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

let questionCount = int(nextInt(inputData, scanPos))
let firstCost = nextInt(inputData, scanPos)
let copyCost = nextInt(inputData, scanPos)
let timeLimit = nextInt(inputData, scanPos)
let pairCount = int(nextInt(inputData, scanPos))

var parentNodes = newSeq[int](questionCount + 1)
var componentSizes = newSeq[int](questionCount + 1)
for nodeIndex in 0 .. questionCount:
  parentNodes[nodeIndex] = nodeIndex
  componentSizes[nodeIndex] = 1

proc findRoot(nodeIndex: int): int =
  var current = nodeIndex
  while parentNodes[current] != current:
    parentNodes[current] = parentNodes[parentNodes[current]]
    current = parentNodes[current]
  return current

proc joinNodes(firstNode, secondNode: int) =
  var firstRoot = findRoot(firstNode)
  var secondRoot = findRoot(secondNode)
  if firstRoot == secondRoot:
    return
  if componentSizes[firstRoot] < componentSizes[secondRoot]:
    swap(firstRoot, secondRoot)
  parentNodes[secondRoot] = firstRoot
  componentSizes[firstRoot] = componentSizes[firstRoot] + componentSizes[secondRoot]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var pairIndex = 0
while pairIndex < pairCount:
  let leftQuestion = int(nextInt(inputData, scanPos))
  let rightQuestion = int(nextInt(inputData, scanPos))
  joinNodes(leftQuestion, rightQuestion)
  pairIndex += 1

var componentCount = 0
for nodeIndex in 1 .. questionCount:
  if findRoot(nodeIndex) == nodeIndex:
    componentCount += 1

let totalTime = int64(componentCount) * firstCost +
                int64(questionCount - componentCount) * copyCost
if totalTime <= timeLimit:
  appendOutput("YES\n")
else:
  appendOutput("NO\n")
stdout.write outputBuffer
outputBuffer.setLen 0
