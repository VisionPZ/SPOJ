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
for caseIndex in 0 .. caseCount - 1:
  let pairCount = nextInt(inputData, scanPos)
  var originalPairs = newSeq[seq[bool]](pairCount)
  var reachablePairs = newSeq[seq[bool]](pairCount)
  for vertex in 0 .. pairCount - 1:
    originalPairs[vertex] = newSeq[bool](pairCount)
    reachablePairs[vertex] = newSeq[bool](pairCount)
    for neighbor in 0 .. pairCount - 1:
      originalPairs[vertex][neighbor] = false
      reachablePairs[vertex][neighbor] = false
  for pairIndex in 0 .. pairCount - 1:
    let startVertex = nextInt(inputData, scanPos)
    let endVertex = nextInt(inputData, scanPos)
    originalPairs[startVertex][endVertex] = true
    reachablePairs[startVertex][endVertex] = true
  for viaVertex in 0 .. pairCount - 1:
    for startVertex in 0 .. pairCount - 1:
      if reachablePairs[startVertex][viaVertex]:
        for endVertex in 0 .. pairCount - 1:
          if reachablePairs[viaVertex][endVertex]:
            reachablePairs[startVertex][endVertex] = true
  var missingPairs = 0
  for startVertex in 0 .. pairCount - 1:
    for endVertex in 0 .. pairCount - 1:
      if reachablePairs[startVertex][endVertex] and not originalPairs[startVertex][endVertex]:
        missingPairs += 1
  appendOutput("Case #" & $(caseIndex + 1) & ": " & $missingPairs)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
