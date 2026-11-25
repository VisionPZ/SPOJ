const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const smallMinusFour = -4
const smallMinusThree = -3
const smallMinusTwo = -2
const exceptionTwo = 2
const exceptionOne = 1
const exceptionFive = 5

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sectionCount = nextInt(inputData, scanPos)
  for sectionIndex in 0 .. sectionCount - 1:
    let sectionValue = nextInt(inputData, scanPos)
    var enteredValue = smallMinusFour
    if sectionValue < 0:
      enteredValue = sectionValue
    elif sectionValue == exceptionTwo:
      enteredValue = smallMinusTwo
    elif sectionValue == exceptionOne or sectionValue == exceptionFive:
      enteredValue = smallMinusThree
    if sectionIndex > 0:
      appendOutput(" ")
    appendOutput($enteredValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
