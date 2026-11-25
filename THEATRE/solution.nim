const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007

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

let heightCount = nextInt(inputData, scanPos)
var heights = newSeq[int](heightCount)
for heightIndex in 0 .. heightCount - 1:
  heights[heightIndex] = nextInt(inputData, scanPos)

var blockingStack = newSeq[int](heightCount)
var stackSize = 0
var productValue: int64 = 1
var currentPosition = heightCount - 1
while currentPosition >= 0:
  let currentHeight = heights[currentPosition]
  while stackSize > 0 and heights[blockingStack[stackSize - 1]] <= currentHeight:
    stackSize -= 1
  var blockerHeight = 1
  if stackSize > 0:
    blockerHeight = heights[blockingStack[stackSize - 1]]
  productValue = (productValue * int64(blockerHeight)) mod int64(modulusValue)
  blockingStack[stackSize] = currentPosition
  stackSize += 1
  currentPosition -= 1

appendOutput($productValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
