const firstDigitValue = 48
const emptyChild = -1
const maxNodes = 50
const flushBlockBytes = 1 shl 18

var leftChild: array[maxNodes + 1, int]
var rightChild: array[maxNodes + 1, int]
var nodeWeight: array[maxNodes + 1, int]

proc nextInt(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ': position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var digitValue = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    digitValue = digitValue * 10 + int(data[position]) - firstDigitValue
    position += 1
  return sign * digitValue

proc subtreeTotal(node: int): int =
  if node == emptyChild: return 0
  let leftTotal = subtreeTotal(leftChild[node])
  let rightTotal = subtreeTotal(rightChild[node])
  nodeWeight[node] = 1 + leftTotal + rightTotal
  return 2 * nodeWeight[node] - 1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

while true:
  let nodeCount = nextInt(inputData, scanPos)
  if nodeCount == 0: break
  var isChild: array[maxNodes + 1, bool]
  for node in 1 .. nodeCount:
    let leftValue = nextInt(inputData, scanPos)
    let rightValue = nextInt(inputData, scanPos)
    leftChild[node] = leftValue
    rightChild[node] = rightValue
    if leftValue != emptyChild: isChild[leftValue] = true
    if rightValue != emptyChild: isChild[rightValue] = true
  var rootNode = 1
  while rootNode <= nodeCount and isChild[rootNode]: rootNode += 1
  discard subtreeTotal(rootNode)
  for node in 1 .. nodeCount:
    if node > 1: outputBuffer.add ' '
    outputBuffer.add $nodeWeight[node]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
