const flushBlockBytes = 1 shl 17
const numbersPerGroup = 5
const evenDivisor = 2
const oddDivisor = 5
const decimalBase = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int, value: var int64): bool =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return false
  var negative = false
  if data[pos] == '-':
    negative = true
    pos += 1
  var magnitude: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    magnitude = magnitude * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    value = -magnitude
  else:
    value = magnitude
  return true

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  var groupTotal: int64 = 0
  var numbersRead = 0
  for numberIndex in 0 .. numbersPerGroup - 1:
    var currentValue: int64 = 0
    if not nextInt(inputData, scanPos, currentValue):
      break
    groupTotal = groupTotal + currentValue
    numbersRead += 1
  if numbersRead == 0:
    break
  var divisor = oddDivisor
  if groupTotal mod evenDivisor == 0:
    divisor = evenDivisor
  var magnitude = groupTotal
  var sign = ""
  if magnitude < 0:
    sign = "-"
    magnitude = -magnitude
  let wholePart = magnitude div int64(divisor)
  let remainder = magnitude mod int64(divisor)
  let fractionalDigit = remainder * int64(decimalBase div divisor)
  appendOutput(sign & $wholePart & "." & $fractionalDigit & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
