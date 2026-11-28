const flushBlockBytes = 1 shl 17
const answerModulus = 1908
const maxTreeSize = 1000

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

var catalanValues = newSeq[int](maxTreeSize + 1)
catalanValues[0] = 1
for treeSize in 1 .. maxTreeSize:
  var shapeTotal: int64 = 0
  for leftSize in 0 .. treeSize - 1:
    shapeTotal = shapeTotal + int64(catalanValues[leftSize]) * int64(catalanValues[treeSize - 1 - leftSize])
  catalanValues[treeSize] = int(shapeTotal mod int64(answerModulus))

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let treeCount = nextInt(inputData, scanPos)
  appendOutput($catalanValues[treeCount])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
