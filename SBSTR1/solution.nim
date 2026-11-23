const flushBlockBytes = 1 shl 16

proc nextToken(data: string, scanPos: var int): tuple[first: int, length: int] =
  while scanPos < data.len and data[scanPos] <= ' ':
    scanPos += 1
  let tokenStart = scanPos
  while scanPos < data.len and data[scanPos] > ' ':
    scanPos += 1
  result.first = tokenStart
  result.length = scanPos - tokenStart

proc containsPattern(data: string, textStart, textLen, patternStart, patternLen: int): bool =
  if patternLen > textLen:
    return false
  var startOffset = 0
  while startOffset + patternLen <= textLen:
    var matched = true
    var patternIndex = 0
    while patternIndex < patternLen:
      if data[textStart + startOffset + patternIndex] != data[patternStart + patternIndex]:
        matched = false
        break
      patternIndex += 1
    if matched:
      return true
    startOffset += 1
  return false

var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add(lineBuffer)
  inputData.add('\n')

var scanPos = 0
var outputBuffer = ""

while true:
  let textToken = nextToken(inputData, scanPos)
  if textToken.length == 0:
    break
  let patternToken = nextToken(inputData, scanPos)
  if patternToken.length == 0:
    break
  if containsPattern(inputData, textToken.first, textToken.length, patternToken.first, patternToken.length):
    outputBuffer.add('1')
  else:
    outputBuffer.add('0')
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

if outputBuffer.len > 0:
  stdout.write(outputBuffer)
