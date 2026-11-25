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

let treeCount = nextInt(inputData, scanPos)
let requiredWood = nextInt(inputData, scanPos)
var treeHeights = newSeq[int](treeCount)
var maxHeight = 0
for treeIndex in 0 .. treeCount - 1:
  let currentHeight = nextInt(inputData, scanPos)
  treeHeights[treeIndex] = currentHeight
  if currentHeight > maxHeight:
    maxHeight = currentHeight

var lowHeight = 0
var highHeight = maxHeight
while lowHeight < highHeight:
  let middleHeight = (lowHeight + highHeight + 1) div 2
  var collectedWood: int64 = 0
  for treeIndex in 0 .. treeCount - 1:
    if treeHeights[treeIndex] > middleHeight:
      collectedWood = collectedWood + int64(treeHeights[treeIndex] - middleHeight)
  if collectedWood >= int64(requiredWood):
    lowHeight = middleHeight
  else:
    highHeight = middleHeight - 1

appendOutput($lowHeight)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
