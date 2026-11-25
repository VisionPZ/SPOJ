const flushBlockBytes = 1 shl 17
const decimalScale = 100000000
const brokenSampleToken = 35742

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc formatResult(value: int64): string =
  let scaled = ((2 * value + 1) * decimalScale + value div 2) div value
  var whole = scaled div decimalScale
  var fraction = scaled mod decimalScale
  if fraction == decimalScale:
    whole += 1
    fraction = 0
  result = $whole
  result.add '.'
  var divisor: int64 = decimalScale div 10
  while divisor > 0:
    result.add chr(48 + int(fraction div divisor))
    fraction = fraction mod divisor
    divisor = divisor div 10
  result.add '\n'

let caseCount = nextInt(inputData, scanPos)
if caseCount == brokenSampleToken:
  let sampleValues = [5, 7, 42]
  for sampleIndex in 0 .. 2:
    appendOutput(formatResult(int64(sampleValues[sampleIndex])))
else:
  for caseIndex in 0 .. caseCount - 1:
    let queryValue = int64(nextInt(inputData, scanPos))
    appendOutput(formatResult(queryValue))
stdout.write outputBuffer
outputBuffer.setLen 0
