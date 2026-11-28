const flushBlockBytes = 1 shl 17
const firstLowerLetter = 97
const morseCodes = [".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---", "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-", "..-", "...-", ".--", "-..-", "-.--", "--.."]

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

proc nextRawLine(data: string, pos: var int): string =
  if pos >= data.len:
    return ""
  var lineEnd = pos
  while lineEnd < data.len and data[lineEnd] != '\n':
    lineEnd += 1
  let rawText = data[pos .. lineEnd - 1]
  pos = lineEnd + 1
  return rawText

proc letterDuration(code: string): int =
  var duration = 0
  for symbolIndex in 0 .. code.len - 1:
    if code[symbolIndex] == '-':
      duration += 3
    else:
      duration += 1
    if symbolIndex < code.len - 1:
      duration += 1
  return duration

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let messageCount = nextInt(inputData, scanPos)
discard nextRawLine(inputData, scanPos)
for messageIndex in 0 .. messageCount - 1:
  let message = nextRawLine(inputData, scanPos)
  var totalLength = 0
  var previousWasLetter = false
  var messageHasLetter = false
  for charIndex in 0 .. message.len - 1:
    let currentLetter = message[charIndex]
    if currentLetter >= 'a' and currentLetter <= 'z':
      if previousWasLetter:
        totalLength += 3
      elif messageHasLetter:
        totalLength += 7
      totalLength += letterDuration(morseCodes[int(currentLetter) - firstLowerLetter])
      previousWasLetter = true
      messageHasLetter = true
    elif currentLetter == ' ':
      previousWasLetter = false
  appendOutput(message)
  appendOutput(": length = ")
  appendOutput($totalLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
