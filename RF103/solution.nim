const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLineBounds(data: string, pos: var int): tuple[first, last: int] =
  var lineStart = pos
  while lineStart < data.len and (data[lineStart] == '\n' or data[lineStart] == '\r'):
    inc lineStart
  var lineEnd = lineStart
  while lineEnd < data.len and data[lineEnd] != '\n' and data[lineEnd] != '\r':
    inc lineEnd
  pos = lineEnd
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    inc pos
  result = (lineStart, lineEnd)

proc containsText(haystack: string, needle: string): bool =
  if needle.len == 0:
    return true
  if needle.len > haystack.len:
    return false
  for startPos in 0..(haystack.len - needle.len):
    var matches = true
    for offset in 0..<needle.len:
      if haystack[startPos + offset] != needle[offset]:
        matches = false
        break
    if matches:
      return true
  return false

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

while scanPos < inputData.len:
  let lineBounds = nextLineBounds(inputData, scanPos)
  let lineStart = lineBounds.first
  let lineEnd = lineBounds.last
  if lineStart == lineEnd:
    continue
  var onlyZero = true
  for position in lineStart..<lineEnd:
    if inputData[position] > ' ' and inputData[position] != '0':
      onlyZero = false
      break
  if onlyZero:
    break

  var braceStart = lineStart
  while braceStart < lineEnd and inputData[braceStart] != '{':
    inc braceStart
  var braceEnd = braceStart
  while braceEnd < lineEnd and inputData[braceEnd] != '}':
    inc braceEnd
  var messageStart = braceEnd
  while messageStart < lineEnd and inputData[messageStart] != '"':
    inc messageStart
  var messageEnd = messageStart + 1
  while messageEnd < lineEnd and inputData[messageEnd] != '"':
    inc messageEnd

  var message = ""
  if messageStart + 1 < messageEnd:
    message = inputData[messageStart + 1 .. messageEnd - 1]

  var allPresent = true
  var wordCursor = braceStart + 1
  while wordCursor < braceEnd:
    while wordCursor < braceEnd and inputData[wordCursor] != '"':
      inc wordCursor
    if wordCursor >= braceEnd:
      break
    let wordStart = wordCursor + 1
    var wordEnd = wordStart
    while wordEnd < braceEnd and inputData[wordEnd] != '"':
      inc wordEnd
    if wordEnd > wordStart:
      let word = inputData[wordStart .. wordEnd - 1]
      if not containsText(message, word):
        allPresent = false
        break
    wordCursor = wordEnd + 1

  if allPresent:
    appendOutput("true\n")
  else:
    appendOutput("false\n")

stdout.write outputBuffer
outputBuffer.setLen 0
