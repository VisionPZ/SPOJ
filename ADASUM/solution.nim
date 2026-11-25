const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextDigitValue(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return -1
  let digitValue = int(data[pos]) - 48
  pos += 1
  return digitValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var digitValues = newSeq[int8]()
var currentDigit = nextDigitValue(inputData, scanPos)
while currentDigit >= 0:
  digitValues.add int8(currentDigit)
  currentDigit = nextDigitValue(inputData, scanPos)

let digitCount = digitValues.len
var repunitValue: int64 = 1
var subsequenceSum: int64 = 0
var digitIndex = digitCount - 1
while digitIndex >= 0:
  let digitValue = int64(digitValues[digitIndex])
  let startCount = int64(digitIndex + 1)
  subsequenceSum = (subsequenceSum + digitValue * startCount * repunitValue) mod int64(modulusValue)
  repunitValue = (repunitValue * 10 + 1) mod int64(modulusValue)
  digitIndex -= 1
appendOutput($subsequenceSum)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
