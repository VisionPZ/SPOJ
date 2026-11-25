import sequtils

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

proc nextRow(data: string, pos: var int, rowLength: int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  for columnIndex in 0 .. rowLength - 1:
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var knownRows: seq[string]
var personCount = 0
var visited: seq[bool]
var lowValue: seq[int]
var discoveryValue: seq[int]
var stackNodes: seq[int]
var onStack: seq[bool]
var timerValue = 0
var groupCount = 0

proc strongConnect(node: int) =
  visited[node] = true
  lowValue[node] = timerValue
  discoveryValue[node] = timerValue
  timerValue += 1
  stackNodes.add node
  onStack[node] = true
  for neighbor in 0 .. personCount - 1:
    if knownRows[node][neighbor] == 'Y':
      if not visited[neighbor]:
        strongConnect(neighbor)
        if lowValue[neighbor] < lowValue[node]:
          lowValue[node] = lowValue[neighbor]
      elif onStack[neighbor]:
        if discoveryValue[neighbor] < lowValue[node]:
          lowValue[node] = discoveryValue[neighbor]
  if lowValue[node] == discoveryValue[node]:
    groupCount += 1
    while true:
      let topNode = stackNodes.pop()
      onStack[topNode] = false
      if topNode == node: break

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  personCount = nextInt(inputData, scanPos)
  knownRows = newSeq[string](personCount)
  for rowIndex in 0 .. personCount - 1:
    knownRows[rowIndex] = nextRow(inputData, scanPos, personCount)
  visited = repeat(false, personCount)
  lowValue = newSeq[int](personCount)
  discoveryValue = newSeq[int](personCount)
  onStack = repeat(false, personCount)
  stackNodes = newSeq[int](0)
  timerValue = 0
  groupCount = 0
  for personIndex in 0 .. personCount - 1:
    if not visited[personIndex]:
      strongConnect(personIndex)
  appendOutput($groupCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
