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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'Z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'A' and data[pos] <= 'Z':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let text = nextWord(inputData, scanPos)
  let textLength = text.len
  var zValues = newSeq[int](textLength)
  if textLength > 0:
    zValues[0] = textLength
  var boxLeft = 0
  var boxRight = 0
  for shiftLength in 1 .. textLength - 1:
    if shiftLength < boxRight:
      zValues[shiftLength] = min(boxRight - shiftLength,
          zValues[shiftLength - boxLeft])
    while shiftLength + zValues[shiftLength] < textLength and
        text[zValues[shiftLength]] == text[shiftLength + zValues[shiftLength]]:
      zValues[shiftLength] += 1
    if shiftLength + zValues[shiftLength] > boxRight:
      boxLeft = shiftLength
      boxRight = shiftLength + zValues[shiftLength]
  var totalMatches = int64(textLength) * int64(textLength + 1) div 2
  for shiftLength in 1 .. textLength - 1:
    totalMatches += int64(zValues[shiftLength])
  appendOutput($totalMatches)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
