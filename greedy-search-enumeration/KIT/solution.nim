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

proc isSeparator(character: char): bool =
  return character == ' ' or character == '\n' or character == '\r' or character == '\t'

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and isSeparator(data[pos]):
    pos += 1
  result = ""
  while pos < data.len and not isSeparator(data[pos]):
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let padSize = nextInt(inputData, scanPos)
var padValues = newSeq[int](padSize)
for padIndex in 0 .. padSize - 1:
  padValues[padIndex] = nextInt(inputData, scanPos)
var padCursor = 0
while true:
  let word = nextToken(inputData, scanPos)
  if word.len == 0:
    break
  if word == "-1":
    break
  var encryptedWord = newString(word.len)
  for charIndex in 0 .. word.len - 1:
    let shift = padValues[padCursor]
    padCursor += 1
    let letterCode = int(word[charIndex]) - int('a')
    encryptedWord[charIndex] = chr((letterCode + shift) mod 26 + int('a'))
  appendOutput(encryptedWord)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
