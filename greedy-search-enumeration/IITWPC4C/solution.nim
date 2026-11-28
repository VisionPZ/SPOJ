const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const gridWidth = 4001
const gridOffset = 2000
const gridLimit = 2000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

proc hasVector(present: seq[bool], xValue, yValue: int): bool =
  if xValue == 0 and yValue == 0:
    return false
  if xValue < -gridLimit or xValue > gridLimit or yValue < -gridLimit or yValue > gridLimit:
    return false
  return present[(xValue + gridOffset) * gridWidth + (yValue + gridOffset)]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextSignedInt(inputData, scanPos)
var present = newSeq[bool](gridWidth * gridWidth)
for caseIndex in 0 .. caseCount - 1:
  let vectorCount = nextSignedInt(inputData, scanPos)
  var vectorX = newSeq[int](vectorCount)
  var vectorY = newSeq[int](vectorCount)
  for vectorIndex in 0 .. vectorCount - 1:
    let xValue = nextSignedInt(inputData, scanPos)
    let yValue = nextSignedInt(inputData, scanPos)
    vectorX[vectorIndex] = xValue
    vectorY[vectorIndex] = yValue
    present[(xValue + gridOffset) * gridWidth + (yValue + gridOffset)] = true
  var found = false
  for leftIndex in 0 .. vectorCount - 1:
    for rightIndex in leftIndex + 1 .. vectorCount - 1:
      let leftX = vectorX[leftIndex]
      let leftY = vectorY[leftIndex]
      let rightX = vectorX[rightIndex]
      let rightY = vectorY[rightIndex]
      if leftX * rightY - leftY * rightX == 0:
        continue
      if hasVector(present, leftX + rightX, leftY + rightY):
        found = true
        break
    if found:
      break
  for vectorIndex in 0 .. vectorCount - 1:
    present[(vectorX[vectorIndex] + gridOffset) * gridWidth + (vectorY[vectorIndex] + gridOffset)] = false
  if found:
    appendOutput "YES\n"
  else:
    appendOutput "NO\n"
stdout.write outputBuffer
outputBuffer.setLen 0
