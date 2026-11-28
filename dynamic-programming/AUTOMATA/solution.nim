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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc wildcardMatch(pattern: string, text: string): bool =
  var textPos = 0
  var patternPos = 0
  var lastStar = -1
  var starTextPos = 0
  while textPos < text.len:
    if patternPos < pattern.len and (pattern[patternPos] == '?' or pattern[patternPos] == text[textPos]):
      textPos += 1
      patternPos += 1
    elif patternPos < pattern.len and pattern[patternPos] == '*':
      lastStar = patternPos
      patternPos += 1
      starTextPos = textPos
    elif lastStar >= 0:
      patternPos = lastStar + 1
      starTextPos += 1
      textPos = starTextPos
    else:
      return false
  while patternPos < pattern.len and pattern[patternPos] == '*':
    patternPos += 1
  return patternPos == pattern.len

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let language = nextToken(inputData, scanPos)
  let subject = nextToken(inputData, scanPos)
  if wildcardMatch(language, subject):
    appendOutput("Yes\n")
  else:
    appendOutput("No\n")
stdout.write outputBuffer
outputBuffer.setLen 0
