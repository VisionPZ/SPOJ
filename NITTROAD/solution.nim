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

proc nextQueryKind(data: string, pos: var int): int =
  while pos < data.len and data[pos] != 'Q' and data[pos] != 'R':
    pos += 1
  if pos < data.len:
    if data[pos] == 'R':
      result = 1
    else:
      result = 0
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var parentNode: seq[int]
var componentSize: seq[int]

proc findRoot(node: int): int =
  var current = node
  while parentNode[current] != current:
    parentNode[current] = parentNode[parentNode[current]]
    current = parentNode[current]
  return current

var connectedPairs: int64 = 0

proc uniteNodes(firstNode, secondNode: int) =
  var firstRoot = findRoot(firstNode)
  var secondRoot = findRoot(secondNode)
  if firstRoot == secondRoot:
    return
  if componentSize[firstRoot] < componentSize[secondRoot]:
    let swapRoot = firstRoot
    firstRoot = secondRoot
    secondRoot = swapRoot
  parentNode[secondRoot] = firstRoot
  connectedPairs += int64(componentSize[firstRoot]) * int64(componentSize[secondRoot])
  componentSize[firstRoot] += componentSize[secondRoot]

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let hostelCount = nextInt(inputData, scanPos)
  var edgeFirst = newSeq[int](hostelCount)
  var edgeSecond = newSeq[int](hostelCount)
  for edgeNumber in 1 .. hostelCount - 1:
    edgeFirst[edgeNumber] = nextInt(inputData, scanPos)
    edgeSecond[edgeNumber] = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var queryKind = newSeq[int](queryCount)
  var queryEdge = newSeq[int](queryCount)
  var removedEdge = newSeq[bool](hostelCount)
  for queryIndex in 0 .. queryCount - 1:
    queryKind[queryIndex] = nextQueryKind(inputData, scanPos)
    if queryKind[queryIndex] == 1:
      queryEdge[queryIndex] = nextInt(inputData, scanPos)
      removedEdge[queryEdge[queryIndex]] = true
  parentNode = newSeq[int](hostelCount + 1)
  componentSize = newSeq[int](hostelCount + 1)
  for hostel in 1 .. hostelCount:
    parentNode[hostel] = hostel
    componentSize[hostel] = 1
  connectedPairs = 0
  for edgeNumber in 1 .. hostelCount - 1:
    if not removedEdge[edgeNumber]:
      uniteNodes(edgeFirst[edgeNumber], edgeSecond[edgeNumber])
  let totalPairs = int64(hostelCount) * int64(hostelCount - 1) div 2
  var answers = newSeq[int64](queryCount)
  var reverseIndex = queryCount - 1
  while reverseIndex >= 0:
    if queryKind[reverseIndex] == 0:
      answers[reverseIndex] = totalPairs - connectedPairs
    else:
      let edgeNumber = queryEdge[reverseIndex]
      uniteNodes(edgeFirst[edgeNumber], edgeSecond[edgeNumber])
    reverseIndex -= 1
  for queryIndex in 0 .. queryCount - 1:
    if queryKind[queryIndex] == 0:
      appendOutput($answers[queryIndex])
      outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
