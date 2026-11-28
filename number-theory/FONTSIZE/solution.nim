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

let billboardWidth = nextInt(inputData, scanPos)
let billboardHeight = nextInt(inputData, scanPos)
var messageStart = scanPos
while messageStart < inputData.len and inputData[messageStart] != '\n':
  messageStart += 1
while messageStart < inputData.len and (inputData[messageStart] == '\n' or
    inputData[messageStart] == '\r' or inputData[messageStart] == ' ' or
    inputData[messageStart] == '\t'):
  messageStart += 1
var messageEnd = messageStart
while messageEnd < inputData.len and inputData[messageEnd] != '\n' and
    inputData[messageEnd] != '\r':
  messageEnd += 1
let message = inputData[messageStart .. messageEnd - 1]

proc fits(sizeScaled: int64): bool =
  if sizeScaled <= 0:
    return true
  let widthScaled = int64(billboardWidth) * 3000
  let heightScaled = int64(billboardHeight) * 1000
  let allowedLines = heightScaled div sizeScaled
  if allowedLines <= 0:
    return false
  var usedLines: int64 = 1
  var usedWidth: int64 = 0
  var wordStart = 0
  while wordStart < message.len:
    var wordEnd = wordStart
    while wordEnd < message.len and message[wordEnd] != ' ':
      wordEnd += 1
    let wordWidth = 2 * sizeScaled * int64(wordEnd - wordStart)
    if wordWidth > widthScaled:
      return false
    if usedWidth == 0:
      usedWidth = wordWidth
    elif usedWidth + 2 * sizeScaled + wordWidth <= widthScaled:
      usedWidth = usedWidth + 2 * sizeScaled + wordWidth
    else:
      usedLines += 1
      if usedLines > allowedLines:
        return false
      usedWidth = wordWidth
    wordStart = wordEnd
    while wordStart < message.len and message[wordStart] == ' ':
      wordStart += 1
  return true

var lowSize = int64(0)
var highSize = int64(billboardHeight) * 1000
let widthCap = int64(billboardWidth) * 1500
if widthCap < highSize:
  highSize = widthCap
while lowSize < highSize:
  let middleSize = lowSize + (highSize - lowSize + 1) div 2
  if fits(middleSize):
    lowSize = middleSize
  else:
    highSize = middleSize - 1

let wholeInches = lowSize div 1000
let fraction = lowSize mod 1000
if fraction == 0:
  appendOutput($wholeInches)
else:
  var fractionText = $fraction
  while fractionText.len > 0 and fractionText[fractionText.len - 1] == '0':
    fractionText.setLen(fractionText.len - 1)
  appendOutput($wholeInches & "." & fractionText)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
