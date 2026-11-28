const flushBlockBytes = 1 shl 17
const bigBase: int64 = 1000000000

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

proc trimBig(value: var seq[int64]) =
  while value.len > 1 and value[value.len - 1] == 0:
    value.setLen(value.len - 1)

proc multiplySmall(value: var seq[int64], factor: int64) =
  var carry: int64 = 0
  for limbIndex in 0 .. value.len - 1:
    let current = value[limbIndex] * factor + carry
    value[limbIndex] = current mod bigBase
    carry = current div bigBase
  while carry > 0:
    value.add carry mod bigBase
    carry = carry div bigBase

proc divideSmall(value: var seq[int64], divisor: int64) =
  var carry: int64 = 0
  var limbIndex = value.len - 1
  while limbIndex >= 0:
    let current = value[limbIndex] + carry * bigBase
    value[limbIndex] = current div divisor
    carry = current mod divisor
    limbIndex -= 1
  trimBig(value)

proc paddedLimb(limb: int64): string =
  result = $limb
  while result.len < 9:
    result = "0" & result

proc bigToString(value: seq[int64]): string =
  result = $value[value.len - 1]
  var limbIndex = value.len - 2
  while limbIndex >= 0:
    result = result & paddedLimb(value[limbIndex])
    limbIndex -= 1

let totalStaff = nextInt(inputData, scanPos)
let neededStaff = nextInt(inputData, scanPos)
var chooseCount = neededStaff
if totalStaff - neededStaff < chooseCount:
  chooseCount = totalStaff - neededStaff
var combinationValue = newSeq[int64](1)
combinationValue[0] = 1
var factorCursor = 1
while factorCursor <= chooseCount:
  multiplySmall(combinationValue, int64(totalStaff - chooseCount + factorCursor))
  divideSmall(combinationValue, int64(factorCursor))
  factorCursor += 1
appendOutput(bigToString(combinationValue) & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
