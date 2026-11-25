const flushBlockBytes = 1 shl 17
const characterKinds = 256

var inputData = ""
var inputLine = ""
var inputLines = newSeq[string]()
while readLine(stdin, inputLine):
  inputLines.add inputLine
  inputData.add inputLine
  inputData.add '\n'

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

var linePos = 0
while linePos + 1 < inputLines.len:
  var headerPos = 0
  let maxDistinct = nextInt(inputLines[linePos], headerPos)
  linePos += 1
  if maxDistinct == 0:
    break
  var typedText = inputLines[linePos]
  linePos += 1
  if typedText.len > 0 and typedText[typedText.len - 1] == '\r':
    typedText.setLen typedText.len - 1
  var occurrences = newSeq[int](characterKinds)
  var distinctCount = 0
  var leftEdge = 0
  var longestRun = 0
  for rightEdge in 0 .. typedText.len - 1:
    let incomingKind = int(typedText[rightEdge])
    if occurrences[incomingKind] == 0:
      distinctCount += 1
    occurrences[incomingKind] += 1
    while distinctCount > maxDistinct:
      let outgoingKind = int(typedText[leftEdge])
      occurrences[outgoingKind] -= 1
      if occurrences[outgoingKind] == 0:
        distinctCount -= 1
      leftEdge += 1
    let runLength = rightEdge - leftEdge + 1
    if runLength > longestRun:
      longestRun = runLength
  appendOutput($longestRun)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
