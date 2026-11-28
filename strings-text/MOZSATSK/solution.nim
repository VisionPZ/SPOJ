const flushBlockBytes = 1 shl 17
const reachOffsets = [-2, -1, 1, 2]
const digitBase = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let keyString = nextToken(inputData, scanPos)
let keyCount = keyString.len
var distances = newSeq[int](keyCount)
for position in 0 .. keyCount - 1:
  distances[position] = -1
var queue = newSeq[int](keyCount)
queue[0] = 0
distances[0] = 0
var queueHead = 0
var queueTail = 1
while queueHead < queueTail:
  let currentPosition = queue[queueHead]
  queueHead += 1
  let currentDigit = int(keyString[currentPosition]) - 48
  for offsetIndex in 0 .. 3:
    let nextPosition = currentPosition + reachOffsets[offsetIndex]
    if nextPosition < 0 or nextPosition >= keyCount:
      continue
    if distances[nextPosition] != -1:
      continue
    let nextDigit = int(keyString[nextPosition]) - 48
    let digitDifference = (nextDigit - currentDigit + digitBase) mod digitBase
    if digitDifference == 0 or digitDifference == 1 or digitDifference == digitBase - 1:
      distances[nextPosition] = distances[currentPosition] + 1
      queue[queueTail] = nextPosition
      queueTail += 1
if distances[keyCount - 1] == -1:
  appendOutput("no\n")
else:
  appendOutput("yes\n")
  appendOutput($(distances[keyCount - 1]))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
