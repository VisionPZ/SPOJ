const flushBlockBytes = 1 shl 17
const maximumValue = 100000
const largestCubeRoot = 46

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

var cubeValues = newSeq[int](largestCubeRoot)
for cubeRoot in 1 .. largestCubeRoot:
  cubeValues[cubeRoot - 1] = cubeRoot * cubeRoot * cubeRoot
var minimumCubes = newSeq[int](maximumValue + 1)
for amount in 1 .. maximumValue:
  minimumCubes[amount] = amount
  for cubeIndex in 0 .. largestCubeRoot - 1:
    let cubeValue = cubeValues[cubeIndex]
    if cubeValue > amount:
      break
    let candidate = minimumCubes[amount - cubeValue] + 1
    if candidate < minimumCubes[amount]:
      minimumCubes[amount] = candidate

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var caseIndex = 1
while true:
  var lookaheadPos = scanPos
  while lookaheadPos < inputData.len and (inputData[lookaheadPos] < '0' or inputData[lookaheadPos] > '9'):
    lookaheadPos += 1
  if lookaheadPos >= inputData.len:
    break
  scanPos = lookaheadPos
  let targetValue = nextInt(inputData, scanPos)
  appendOutput("Case #" & $caseIndex & ": " & $minimumCubes[targetValue])
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
