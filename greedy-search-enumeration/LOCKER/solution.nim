const flushBlockBytes = 1 shl 17
const answerModulus: int64 = 1000000007'i64

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

proc powerModulo(baseValue: int64, exponentValue: int64): int64 =
  var resultValue: int64 = 1
  var currentBase = baseValue mod answerModulus
  var remainingExponent = exponentValue
  while remainingExponent > 0:
    if (remainingExponent and 1'i64) == 1'i64:
      resultValue = (resultValue * currentBase) mod answerModulus
    currentBase = (currentBase * currentBase) mod answerModulus
    remainingExponent = remainingExponent shr 1
  return resultValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let ropeLength = int64(nextInt(inputData, scanPos))
  var answerValue: int64
  if ropeLength <= 3:
    answerValue = ropeLength
  elif ropeLength mod 3 == 0:
    answerValue = powerModulo(3'i64, ropeLength div 3)
  elif ropeLength mod 3 == 1:
    answerValue = (4'i64 * powerModulo(3'i64, (ropeLength - 4'i64) div 3)) mod answerModulus
  else:
    answerValue = (2'i64 * powerModulo(3'i64, (ropeLength - 2'i64) div 3)) mod answerModulus
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
