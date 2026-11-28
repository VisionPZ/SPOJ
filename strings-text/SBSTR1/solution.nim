const flushBlockBytes = 1 shl 16

proc nextToken(data: string, i: var int): tuple[first: int, length: int] =
  while i < data.len and data[i] <= ' ':
    i += 1
  let tokenStart = i
  while i < data.len and data[i] > ' ':
    i += 1
  result.first = tokenStart
  result.length = i - tokenStart

proc containsPattern(data: string, textStart, textLen, patternStart, patternLen: int): bool =
  if patternLen > textLen:
    return false
  var i = 0
  while i + patternLen <= textLen:
    var matched = true
    var j = 0
    while j < patternLen:
      if data[textStart + i + j] != data[patternStart + j]:
        matched = false
        break
      j += 1
    if matched:
      return true
    i += 1
  return false

var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add(lineBuffer)
  inputData.add('\n')

var i = 0
var outputBuffer = ""

while true:
  let textToken = nextToken(inputData, i)
  if textToken.length == 0:
    break
  let patternToken = nextToken(inputData, i)
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
