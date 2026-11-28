const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int): int =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var isNegative = false
  if position < data.len and data[position] == '-':
    isNegative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  if isNegative:
    return -value
  return value

const daysOfMonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

proc isLeapYear(yearValue: int): bool =
  return yearValue mod 400 == 0 or (yearValue mod 4 == 0 and yearValue mod 100 != 0)

proc isValidDate(monthValue, dayValue, yearValue: int): bool =
  if monthValue < 1 or monthValue > 12:
    return false
  var monthLimit = daysOfMonth[monthValue]
  if monthValue == 2 and isLeapYear(yearValue):
    monthLimit += 1
  return dayValue >= 1 and dayValue <= monthLimit

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextSignedInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let monthValue = nextSignedInt(inputData, scanPos)
  let dayValue = nextSignedInt(inputData, scanPos)
  let yearValue = nextSignedInt(inputData, scanPos)
  if isValidDate(monthValue, dayValue, yearValue):
    appendOutput("VALID\n")
  else:
    appendOutput("INVALID\n")

stdout.write outputBuffer
outputBuffer.setLen 0
