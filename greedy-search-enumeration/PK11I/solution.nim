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
for caseIndex in 1 .. caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  var incomingCounts = newSeq[int](nodeCount)
  var outgoingCounts = newSeq[int](nodeCount)
  var edgeIndex = 1
  while edgeIndex < nodeCount:
    let fromNode = nextInt(inputData, scanPos)
    let toNode = nextInt(inputData, scanPos)
    outgoingCounts[fromNode] += 1
    incomingCounts[toNode] += 1
    edgeIndex += 1
  var pathCount = 0
  for nodeIndex in 0 .. nodeCount - 1:
    if incomingCounts[nodeIndex] > outgoingCounts[nodeIndex]:
      pathCount += incomingCounts[nodeIndex] - outgoingCounts[nodeIndex]
  appendOutput("Case " & $caseIndex & ": " & $pathCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
