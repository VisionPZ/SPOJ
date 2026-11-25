import strutils

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let savedPos = scanPos
  let height = nextInt(inputData, scanPos)
  if scanPos == savedPos:
    break
  for rowIndex in 1..height:
    appendOutput(repeat(' ', 2 * (height - rowIndex)))
    let starCount = 2 * rowIndex - 1
    for starIndex in 1..starCount:
      if starIndex != 1:
        appendOutput(" ")
      appendOutput("*")
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
