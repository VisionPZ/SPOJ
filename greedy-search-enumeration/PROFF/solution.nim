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

while scanPos < inputData.len:
  let firstNumber = nextInt(inputData, scanPos)
  let secondNumber = nextInt(inputData, scanPos)
  if firstNumber == 0 and secondNumber == 0:
    break
  var carryCount = 0
  var carryDigit = 0
  var leftNumber = firstNumber
  var rightNumber = secondNumber
  while leftNumber > 0 or rightNumber > 0:
    let digitSum = leftNumber mod 10 + rightNumber mod 10 + carryDigit
    if digitSum >= 10:
      carryCount += 1
      carryDigit = 1
    else:
      carryDigit = 0
    leftNumber = leftNumber div 10
    rightNumber = rightNumber div 10
  if carryCount == 0:
    appendOutput("No carry operation.\n")
  elif carryCount == 1:
    appendOutput("1 carry operation.\n")
  else:
    appendOutput($carryCount)
    appendOutput(" carry operations.\n")

stdout.write outputBuffer
outputBuffer.setLen 0
