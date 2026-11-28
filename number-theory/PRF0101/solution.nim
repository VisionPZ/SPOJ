const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var isNegative = false
  if pos < data.len and data[pos] == '-':
    isNegative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if isNegative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let enteredNumber = nextInt(inputData, scanPos)
appendOutput("Please enter any integer: ")
if enteredNumber > 0:
  appendOutput($enteredNumber & " is a positive number")
elif enteredNumber < 0:
  appendOutput($enteredNumber & " is a negative number")
else:
  appendOutput("The number entered is zero")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
