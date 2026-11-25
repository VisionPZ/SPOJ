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

proc hasDigits(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasDigits(inputData, scanPos):
  let childCount = nextInt(inputData, scanPos)
  let neighbourCount = nextInt(inputData, scanPos)
  if childCount == 0 and neighbourCount == 0:
    break
  var firstSeenAt = newSeq[int](childCount)
  for remainderIndex in 0 .. childCount - 1:
    firstSeenAt[remainderIndex] = -1
  var runningRemainder = 0
  var firstNeighbour = -1
  var lastNeighbour = -1
  for neighbourIndex in 1 .. neighbourCount:
    let sweets = nextInt(inputData, scanPos)
    runningRemainder = (runningRemainder + sweets) mod childCount
    if firstNeighbour == -1:
      if runningRemainder == 0:
        firstNeighbour = 1
        lastNeighbour = neighbourIndex
      elif firstSeenAt[runningRemainder] != -1:
        firstNeighbour = firstSeenAt[runningRemainder] + 1
        lastNeighbour = neighbourIndex
      else:
        firstSeenAt[runningRemainder] = neighbourIndex
  if firstNeighbour == -1:
    appendOutput("no sweets")
    outputBuffer.add '\n'
  else:
    var outputIndex = firstNeighbour
    while outputIndex <= lastNeighbour:
      appendOutput($outputIndex)
      if outputIndex == lastNeighbour:
        outputBuffer.add '\n'
      else:
        outputBuffer.add ' '
      outputIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
