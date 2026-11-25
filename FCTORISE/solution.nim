const flushBlockBytes = 1 shl 17

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

proc integerSquareRoot(value: int64): int64 =
  var lowBound: int64 = 0
  var highBound: int64 = value
  while lowBound < highBound:
    let middle = (lowBound + highBound + 1) div 2
    if middle <= value div middle:
      lowBound = middle
    else:
      highBound = middle - 1
  return lowBound

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberValue = int64(nextInt(inputData, scanPos))
  var factorBelow = integerSquareRoot(numberValue)
  while factorBelow > 1 and numberValue mod factorBelow != 0:
    factorBelow -= 1
  let factorAbove = numberValue div factorBelow
  let squareRootX = (factorBelow + factorAbove) div 2
  let squareRootY = (factorAbove - factorBelow) div 2
  appendOutput($numberValue & " = " & $squareRootX & "^2 - " & $squareRootY & "^2 = " & $factorAbove & "*" & $factorBelow)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
