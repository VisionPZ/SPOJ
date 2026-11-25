const flushBlockBytes = 1 shl 17
const maxCubeCount = 5

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

let targetSum = nextInt(inputData, scanPos)
var maxRoot = 1
while int64(maxRoot + 1) * int64(maxRoot + 1) * int64(maxRoot + 1) <= int64(targetSum):
  maxRoot = maxRoot + 1

var cubeValues = newSeq[int](maxRoot)
for rootValue in 1 .. maxRoot:
  cubeValues[rootValue - 1] = rootValue * rootValue * rootValue

var representationCounts = newSeq[seq[int64]](maxCubeCount + 1)
for countIndex in 0 .. maxCubeCount:
  representationCounts[countIndex] = newSeq[int64](targetSum + 1)
representationCounts[0][0] = 1

for cubeValue in cubeValues:
  for cubeCount in 1 .. maxCubeCount:
    for sumValue in cubeValue .. targetSum:
      representationCounts[cubeCount][sumValue] = representationCounts[cubeCount][sumValue] + representationCounts[cubeCount - 1][sumValue - cubeValue]

var answer: int64 = 0
for cubeCount in 1 .. maxCubeCount:
  answer = answer + representationCounts[cubeCount][targetSum]
appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
