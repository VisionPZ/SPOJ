const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextLastDigit(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var lastDigit = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    lastDigit = ord(data[position]) - firstDigitValue
    position += 1
  return lastDigit

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let firstLastDigit = nextLastDigit(inputData, scanPos)
  let secondLastDigit = nextLastDigit(inputData, scanPos)
  if (firstLastDigit + secondLastDigit) mod 2 == 0:
    appendOutput("even\n")
  else:
    appendOutput("odd\n")

stdout.write outputBuffer
outputBuffer.setLen 0
