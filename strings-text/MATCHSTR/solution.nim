const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
  scanPos += 1
let textStart = scanPos
while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
  scanPos += 1
let textLength = scanPos - textStart
while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
  scanPos += 1
let patternStart = scanPos
while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
  scanPos += 1
let patternLength = scanPos - patternStart

if patternLength == 0 or patternLength > textLength:
  appendOutput("0\n")
else:
  var prefixValue = newSeq[int](patternLength)
  var matchedLength = 0
  for prefixIndex in 1 .. patternLength - 1:
    while matchedLength > 0 and inputData[patternStart + prefixIndex] != inputData[patternStart + matchedLength]:
      matchedLength = prefixValue[matchedLength - 1]
    if inputData[patternStart + prefixIndex] == inputData[patternStart + matchedLength]:
      matchedLength += 1
    prefixValue[prefixIndex] = matchedLength
  var occurrenceCount: int64 = 0
  matchedLength = 0
  for textIndex in 0 .. textLength - 1:
    while matchedLength > 0 and inputData[textStart + textIndex] != inputData[patternStart + matchedLength]:
      matchedLength = prefixValue[matchedLength - 1]
    if inputData[textStart + textIndex] == inputData[patternStart + matchedLength]:
      matchedLength += 1
    if matchedLength == patternLength:
      occurrenceCount += 1
      matchedLength = prefixValue[matchedLength - 1]
  appendOutput($occurrenceCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
