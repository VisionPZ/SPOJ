const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007
const letterCount = 26
const firstLetterValue = 65

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
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let textValue = nextToken(inputData, scanPos)
  var lastCounts = newSeq[int64](letterCount)
  var distinctCount: int64 = 1
  for charIndex in 0 .. textValue.len - 1:
    let letterIndex = int(textValue[charIndex]) - firstLetterValue
    let previousCount = lastCounts[letterIndex]
    let extendedCount = (2 * distinctCount - previousCount + modulusValue) mod modulusValue
    lastCounts[letterIndex] = distinctCount
    distinctCount = extendedCount
  appendOutput($distinctCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
