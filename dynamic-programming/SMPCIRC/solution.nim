const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let firstCenterX = nextInt(inputData, scanPos)
  let firstCenterY = nextInt(inputData, scanPos)
  let firstRadius = nextInt(inputData, scanPos)
  let secondCenterX = nextInt(inputData, scanPos)
  let secondCenterY = nextInt(inputData, scanPos)
  let secondRadius = nextInt(inputData, scanPos)
  let deltaX = firstCenterX - secondCenterX
  let deltaY = firstCenterY - secondCenterY
  let distanceSquared = deltaX * deltaX + deltaY * deltaY
  var largerRadius = firstRadius
  var smallerRadius = secondRadius
  if secondRadius > firstRadius:
    largerRadius = secondRadius
    smallerRadius = firstRadius
  let gap = largerRadius - smallerRadius
  let gapSquared = gap * gap
  if distanceSquared < gapSquared:
    appendOutput("I")
  elif distanceSquared == gapSquared:
    appendOutput("E")
  else:
    appendOutput("O")
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
