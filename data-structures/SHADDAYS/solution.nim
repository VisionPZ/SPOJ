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

proc daysFromCivil(yearValue, monthValue, dayValue: int): int64 =
  var adjustedYear = int64(yearValue)
  let monthNumber = int64(monthValue)
  let dayNumber = int64(dayValue)
  if monthNumber <= 2:
    adjustedYear -= 1
  let era = adjustedYear div 400
  let yearOfEra = adjustedYear - era * 400
  let shiftedMonth = monthNumber + (if monthNumber > 2: -3 else: 9)
  let dayOfYear = (153 * shiftedMonth + 2) div 5 + dayNumber - 1
  let dayOfEra = yearOfEra * 365 + yearOfEra div 4 - yearOfEra div 100 + dayOfYear
  return era * 146097 + dayOfEra - 719468

proc civilFromDays(dayCount: int64): tuple[yearValue: int, monthValue: int, dayValue: int] =
  let shiftedDays = dayCount + 719468
  let era = shiftedDays div 146097
  let dayOfEra = shiftedDays - era * 146097
  let yearOfEra = (dayOfEra - dayOfEra div 1460 + dayOfEra div 36524 - dayOfEra div 146096) div 365
  var calendarYear = yearOfEra + era * 400
  let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra div 4 - yearOfEra div 100)
  let shiftedMonth = (5 * dayOfYear + 2) div 153
  let calendarDay = dayOfYear - (153 * shiftedMonth + 2) div 5 + 1
  var calendarMonth = shiftedMonth + (if shiftedMonth < 10: 3 else: -9)
  if calendarMonth <= 2:
    calendarYear += 1
  return (int(calendarYear), int(calendarMonth), int(calendarDay))

proc paddedNumber(value: int, width: int): string =
  var text = $(value)
  while text.len < width:
    text = "0" & text
  return text

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let startDay = nextInt(inputData, scanPos)
  let startMonth = nextInt(inputData, scanPos)
  let startYear = nextInt(inputData, scanPos)
  let daysToAdd = nextInt(inputData, scanPos)
  let startingDayNumber = daysFromCivil(startYear, startMonth, startDay)
  let resultDate = civilFromDays(startingDayNumber + int64(daysToAdd))
  appendOutput(paddedNumber(resultDate.dayValue, 2) & "-" & paddedNumber(resultDate.monthValue, 2) & "-" & paddedNumber(resultDate.yearValue, 4) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
