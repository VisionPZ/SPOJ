{.push checks: off.}
{.passC: "-O3".}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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

proc nextTokenStart(data: string, pos: var int, length: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  length = pos - startPos
  return startPos

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendNumber(value: int) =
  let oldLen = outputBuffer.len
  outputBuffer.setLen(oldLen + 12)
  var pos = oldLen
  var rest = value
  if rest == 0:
    outputBuffer[pos] = '0'
    pos += 1
  else:
    let firstPos = pos
    while rest > 0:
      outputBuffer[pos] = char(firstDigitValue + rest mod 10)
      rest = rest div 10
      pos += 1
    var lowPos = firstPos
    var highPos = pos - 1
    while lowPos < highPos:
      swap outputBuffer[lowPos], outputBuffer[highPos]
      lowPos += 1
      highPos -= 1
  outputBuffer.setLen(pos)

var border: seq[int] = @[]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let stringLength = nextInt(inputData, scanPos)
  var tokenLength = 0
  let tokenStart = nextTokenStart(inputData, scanPos, tokenLength)

  appendOutput("Test case #")
  appendNumber(caseIndex + 1)
  appendOutput("\n")

  border.setLen(stringLength)
  border[0] = 0
  var matched = 0
  for position in 1..<stringLength:
    let currentChar = inputData[tokenStart + position]
    while matched > 0 and currentChar != inputData[tokenStart + matched]:
      matched = border[matched - 1]
    if currentChar == inputData[tokenStart + matched]:
      matched += 1
    border[position] = matched

  for prefixLength in 1..stringLength:
    let periodLength = prefixLength - border[prefixLength - 1]
    if prefixLength mod periodLength == 0:
      let repetitionCount = prefixLength div periodLength
      if repetitionCount > 1:
        appendNumber(prefixLength)
        outputBuffer.add ' '
        appendNumber(repetitionCount)
        outputBuffer.add '\n'
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
