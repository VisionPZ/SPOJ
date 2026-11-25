const flushBlockBytes = 1 shl 17
const digitsPerLimb = 9
const bigBase: int64 = 1000000000
const largestQuery = 150

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] != '-' and (data[pos] < '0' or data[pos] > '9')):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc multiplyByFactor(numberLimbs: var seq[int], factorValue: int64) =
  var carryValue: int64 = 0
  for limbIndex in 0 .. numberLimbs.len - 1:
    let productValue = int64(numberLimbs[limbIndex]) * factorValue + carryValue
    numberLimbs[limbIndex] = int(productValue mod bigBase)
    carryValue = productValue div bigBase
  while carryValue > 0:
    numberLimbs.add(int(carryValue mod bigBase))
    carryValue = carryValue div bigBase

proc divideByFactor(numberLimbs: var seq[int], divisorValue: int64) =
  var remainderValue: int64 = 0
  var limbIndex = numberLimbs.len - 1
  while limbIndex >= 0:
    let currentValue = remainderValue * bigBase + int64(numberLimbs[limbIndex])
    numberLimbs[limbIndex] = int(currentValue div divisorValue)
    remainderValue = currentValue mod divisorValue
    limbIndex -= 1
  while numberLimbs.len > 1 and numberLimbs[numberLimbs.len - 1] == 0:
    numberLimbs.setLen(numberLimbs.len - 1)

proc formatBigNumber(numberLimbs: seq[int]): string =
  result = $numberLimbs[numberLimbs.len - 1]
  var limbIndex = numberLimbs.len - 2
  while limbIndex >= 0:
    let limbText = $numberLimbs[limbIndex]
    var zeroCount = digitsPerLimb - limbText.len
    while zeroCount > 0:
      result.add '0'
      zeroCount -= 1
    result.add limbText
    limbIndex -= 1

var catalanNumbers = newSeq[seq[int]](largestQuery + 1)
var runningNumber = newSeq[int](1)
runningNumber[0] = 1
catalanNumbers[0] = runningNumber
for orderValue in 0 .. largestQuery - 1:
  var nextNumber = newSeq[int]()
  for limbValue in runningNumber:
    nextNumber.add limbValue
  multiplyByFactor(nextNumber, int64(4 * orderValue + 2))
  divideByFactor(nextNumber, int64(orderValue + 2))
  catalanNumbers[orderValue + 1] = nextNumber
  runningNumber = nextNumber

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let queryValue = nextInt(inputData, scanPos)
  if queryValue < 0:
    break
  appendOutput(formatBigNumber(catalanNumbers[queryValue]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
