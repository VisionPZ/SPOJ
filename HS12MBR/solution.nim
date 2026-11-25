const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const boundSentinel = 2000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextCharacter(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let symbol = data[pos]
  pos += 1
  return symbol

proc nextInteger(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var signValue = 1
  if data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

var outputBuffer = ""
var digitStorage: array[16, char]

proc appendInteger(value: int) =
  if value == 0:
    outputBuffer.add '0'
    return
  var magnitude = value
  if magnitude < 0:
    outputBuffer.add '-'
    magnitude = -magnitude
  var digitCount = 0
  while magnitude > 0:
    digitStorage[digitCount] = char(magnitude mod 10 + firstDigitValue)
    digitCount += 1
    magnitude = magnitude div 10
  while digitCount > 0:
    digitCount -= 1
    outputBuffer.add digitStorage[digitCount]

proc flushOutput() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInteger(inputData, scanPos)
for _ in 0 ..< caseCount:
  let objectCount = nextInteger(inputData, scanPos)
  var minimumX = boundSentinel
  var minimumY = boundSentinel
  var maximumX = -boundSentinel
  var maximumY = -boundSentinel
  for _ in 0 ..< objectCount:
    let kind = nextCharacter(inputData, scanPos)
    case kind
    of 'p':
      let pointX = nextInteger(inputData, scanPos)
      let pointY = nextInteger(inputData, scanPos)
      if pointX < minimumX: minimumX = pointX
      if pointX > maximumX: maximumX = pointX
      if pointY < minimumY: minimumY = pointY
      if pointY > maximumY: maximumY = pointY
    of 'c':
      let centerX = nextInteger(inputData, scanPos)
      let centerY = nextInteger(inputData, scanPos)
      let radius = nextInteger(inputData, scanPos)
      let leftEdge = centerX - radius
      let rightEdge = centerX + radius
      let lowerEdge = centerY - radius
      let upperEdge = centerY + radius
      if leftEdge < minimumX: minimumX = leftEdge
      if rightEdge > maximumX: maximumX = rightEdge
      if lowerEdge < minimumY: minimumY = lowerEdge
      if upperEdge > maximumY: maximumY = upperEdge
    of 'l':
      let firstX = nextInteger(inputData, scanPos)
      let firstY = nextInteger(inputData, scanPos)
      let secondX = nextInteger(inputData, scanPos)
      let secondY = nextInteger(inputData, scanPos)
      let lowX = min(firstX, secondX)
      let highX = max(firstX, secondX)
      let lowY = min(firstY, secondY)
      let highY = max(firstY, secondY)
      if lowX < minimumX: minimumX = lowX
      if highX > maximumX: maximumX = highX
      if lowY < minimumY: minimumY = lowY
      if highY > maximumY: maximumY = highY
    else:
      discard
  appendInteger(minimumX)
  outputBuffer.add ' '
  appendInteger(minimumY)
  outputBuffer.add ' '
  appendInteger(maximumX)
  outputBuffer.add ' '
  appendInteger(maximumY)
  outputBuffer.add '\n'
  flushOutput()
stdout.write outputBuffer
