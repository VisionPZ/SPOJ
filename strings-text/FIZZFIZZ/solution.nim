const flushBlockBytes = 1 shl 17
const fizzDivisor = 3

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

let studentCount = nextInt(inputData, scanPos)
for studentNumber in 1 .. studentCount:
  var remainingValue = studentNumber
  var fizzCount = 0
  while remainingValue mod fizzDivisor == 0:
    fizzCount += 1
    remainingValue = remainingValue div fizzDivisor
  if fizzCount == 0:
    appendOutput($studentNumber & "\n")
  else:
    var fizzPhrase = ""
    for fizzIndex in 0 .. fizzCount - 1:
      if fizzIndex > 0:
        fizzPhrase.add '-'
      fizzPhrase.add "fizz"
    appendOutput(fizzPhrase & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
