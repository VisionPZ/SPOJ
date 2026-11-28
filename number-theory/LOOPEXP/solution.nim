const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const scaleFactor = 1000000000

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

let caseCount = nextInt(inputData, scanPos)
var caseSizes = newSeq[int](caseCount)
var largestSize = 0
var caseIndex = 0
while caseIndex < caseCount:
  caseSizes[caseIndex] = nextInt(inputData, scanPos)
  if caseSizes[caseIndex] > largestSize:
    largestSize = caseSizes[caseIndex]
  caseIndex += 1

var harmonicScaled = newSeq[int64](largestSize + 1)
var runningTotal = 0.0
var sizeIndex = 1
while sizeIndex <= largestSize:
  runningTotal = runningTotal + 1.0 / float64(sizeIndex)
  harmonicScaled[sizeIndex] = int64(runningTotal * float64(scaleFactor) + 0.5)
  sizeIndex += 1

proc formatScaled(scaledValue: int64): string =
  let wholePart = scaledValue div int64(scaleFactor)
  let fractionPart = scaledValue mod int64(scaleFactor)
  if fractionPart == 0:
    return $wholePart
  var fractionText = $fractionPart
  while fractionText.len < 9:
    fractionText = "0" & fractionText
  while fractionText[fractionText.len - 1] == '0':
    fractionText.setLen(fractionText.len - 1)
  return $wholePart & "." & fractionText

caseIndex = 0
while caseIndex < caseCount:
  appendOutput(formatScaled(harmonicScaled[caseSizes[caseIndex]]))
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
