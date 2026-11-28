const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxCode = 10000

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var seenInKnowledge = newSeq[bool](maxCode + 1)
var seenInEnglish = newSeq[bool](maxCode + 1)

let knowledgeCount = nextInt(inputData, scanPos)
for index in 0..<knowledgeCount:
  let code = nextInt(inputData, scanPos)
  if code >= 1 and code <= maxCode:
    seenInKnowledge[code] = true

let englishCount = nextInt(inputData, scanPos)
for index in 0..<englishCount:
  let code = nextInt(inputData, scanPos)
  if code >= 1 and code <= maxCode:
    seenInEnglish[code] = true

var firstCodeWritten = true
for code in 1..maxCode:
  if seenInKnowledge[code] and seenInEnglish[code]:
    if not firstCodeWritten:
      outputBuffer.add ' '
    firstCodeWritten = false
    appendOutput($(code))
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
