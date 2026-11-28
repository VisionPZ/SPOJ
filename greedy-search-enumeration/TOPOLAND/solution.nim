const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value * sign

proc nextCommand(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  if pos >= data.len:
    return ' '
  let command = data[pos]
  pos += 1
  if command >= 'a' and command <= 'z':
    return chr(int(command) - 32)
  return command

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc updateValue(segmentTree: var seq[int64], leafIndex: int, newValue: int64) =
  var nodeIndex = leafIndex
  segmentTree[nodeIndex] = newValue
  nodeIndex = nodeIndex div 2
  while nodeIndex >= 1:
    segmentTree[nodeIndex] = max(segmentTree[nodeIndex * 2], segmentTree[nodeIndex * 2 + 1])
    nodeIndex = nodeIndex div 2

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let partCount = nextInt(inputData, scanPos)
  var houseBalloons = int64(nextInt(inputData, scanPos))
  var segmentSize = 1
  while segmentSize < partCount:
    segmentSize = segmentSize * 2
  var segmentTree = newSeq[int64](segmentSize * 2)
  for partIndex in 0 .. partCount - 1:
    segmentTree[segmentSize + partIndex] = int64(nextInt(inputData, scanPos))
  for nodeIndex in countdown(segmentSize - 1, 1):
    segmentTree[nodeIndex] = max(segmentTree[nodeIndex * 2], segmentTree[nodeIndex * 2 + 1])
  appendOutput("Testcase " & $caseIndex & ":\n")
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    let command = nextCommand(inputData, scanPos)
    if command == 'A':
      houseBalloons = houseBalloons + int64(nextInt(inputData, scanPos))
    elif command == 'B':
      let partIndex = nextInt(inputData, scanPos)
      let newMinimum = int64(nextInt(inputData, scanPos))
      updateValue(segmentTree, segmentSize + partIndex, newMinimum)
    else:
      let leftIndex = nextInt(inputData, scanPos)
      let rightIndex = nextInt(inputData, scanPos)
      var leftNode = segmentSize + leftIndex
      var rightNode = segmentSize + rightIndex
      var bestValue: int64 = -1
      while leftNode <= rightNode:
        if leftNode mod 2 == 1:
          bestValue = max(bestValue, segmentTree[leftNode])
          leftNode += 1
        if rightNode mod 2 == 0:
          bestValue = max(bestValue, segmentTree[rightNode])
          rightNode -= 1
        leftNode = leftNode div 2
        rightNode = rightNode div 2
      appendOutput($(houseBalloons - bestValue))
      outputBuffer.add '\n'
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
