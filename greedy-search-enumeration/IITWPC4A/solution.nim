const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sourceText = nextWord(inputData, scanPos)
  let groupSize = nextInt(inputData, scanPos)
  let producedSize = nextInt(inputData, scanPos)
  var replacementCount: int64 = 0
  var runLength = 0
  for character in sourceText:
    if character == 'a':
      runLength += 1
    else:
      replacementCount += int64(runLength div groupSize)
      runLength = 0
  replacementCount += int64(runLength div groupSize)
  let originalLength = int64(sourceText.len)
  let lengthDelta = int64(producedSize) - int64(groupSize)
  var minimumLength = originalLength
  var maximumLength = originalLength
  if lengthDelta > 0:
    maximumLength += lengthDelta * replacementCount
  elif lengthDelta < 0:
    minimumLength += lengthDelta * replacementCount
  appendOutput($minimumLength & " " & $maximumLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
