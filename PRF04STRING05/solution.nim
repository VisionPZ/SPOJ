const flushBlockBytes = 1 shl 17
const keptCharacterLimit = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var firstLineEnd = 0
while firstLineEnd < inputData.len and inputData[firstLineEnd] != '\n':
  firstLineEnd += 1

var prefixText = ""
var keptCount = 0
while keptCount < keptCharacterLimit and keptCount < firstLineEnd:
  prefixText.add inputData[keptCount]
  keptCount += 1

appendOutput(prefixText)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
