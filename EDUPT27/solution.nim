const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var listValues = newSeq[int]()
while true:
  let scannedValue = nextInt(inputData, scanPos)
  if scannedValue == -1:
    break
  listValues.add scannedValue

var patternValues = newSeq[int]()
while true:
  let scannedValue = nextInt(inputData, scanPos)
  if scannedValue == -1:
    break
  patternValues.add scannedValue

let patternLength = patternValues.len
var survivingValues = newSeq[int]()
for listValue in listValues:
  survivingValues.add listValue
  if patternLength > 0 and survivingValues.len >= patternLength:
    var matchesPattern = true
    for patternIndex in 0 .. patternLength - 1:
      if survivingValues[survivingValues.len - patternLength + patternIndex] != patternValues[patternIndex]:
        matchesPattern = false
        break
    if matchesPattern:
      survivingValues.setLen(survivingValues.len - patternLength)

var firstValueWritten = true
for survivingValue in survivingValues:
  if not firstValueWritten:
    appendOutput(" ")
  appendOutput($survivingValue)
  firstValueWritten = false
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
