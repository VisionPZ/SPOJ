import strutils

const flushBlockBytes = 1 shl 17
const cipherModulus: int64 = 4000000007
const rootExponent: int64 = 1000000002
const lastPossibleSecond: int64 = 1900000000

var weekdayName = ["Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"]
var monthName = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
var monthLength = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var scanPos = 0

proc nextInt(): int64 =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var value: int64 = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(int(inputData[scanPos]) - 48)
    scanPos = scanPos + 1
  return value

proc multiplyMod(firstValue: int64, secondValue: int64): int64 =
  var doublingValue = firstValue
  var runningValue: int64 = 0
  var walker = secondValue
  while walker > 0:
    if (walker and 1) != 0:
      runningValue = (runningValue + doublingValue) mod cipherModulus
    doublingValue = (doublingValue + doublingValue) mod cipherModulus
    walker = walker shr 1
  return runningValue

proc powerMod(baseValue: int64): int64 =
  var multiplier = baseValue
  var answer: int64 = 1
  var walker = rootExponent
  while walker > 0:
    if (walker and 1) != 0: answer = multiplyMod(answer, multiplier)
    multiplier = multiplyMod(multiplier, multiplier)
    walker = walker shr 1
  return answer

proc leapFlag(year: int64): int64 =
  if year mod 4 == 0 and (year mod 100 != 0 or year mod 400 == 0): return 1
  return 0

proc daysInYearOf(year: int64): int64 =
  return 365 + leapFlag(year)

proc daysInMonthOf(year: int64, monthIndex: int): int64 =
  var baseLength = int64(monthLength[monthIndex])
  if monthIndex == 1 and leapFlag(year) == 1: baseLength = 29
  return baseLength

proc isLeapYear(year: int64): bool =
  return leapFlag(year) == 1

proc padTwo(numberValue: int64): string =
  if numberValue < 10: return "0" & $numberValue
  return $numberValue

proc clockLine(timeStamp: int64): string =
  var dayCount = timeStamp div 86400
  var secondsOfDay = timeStamp mod 86400
  var hourValue = secondsOfDay div 3600
  var minuteValue = (secondsOfDay mod 3600) div 60
  var secondValue = secondsOfDay mod 60
  var year: int64 = 1970
  var remainingDays = dayCount
  while true:
    var daysInYear = daysInYearOf(year)
    if remainingDays >= daysInYear:
      remainingDays = remainingDays - daysInYear
      year = year + 1
    else:
      break
  var monthIndex = 0
  var daysInMonth = daysInMonthOf(year, monthIndex)
  while remainingDays >= daysInMonth:
    remainingDays = remainingDays - daysInMonth
    monthIndex = monthIndex + 1
    daysInMonth = daysInMonthOf(year, monthIndex)
  var dayOfMonth = remainingDays + 1
  var result: string
  result.add weekdayName[int(dayCount mod 7)]
  result.add " "
  result.add monthName[monthIndex]
  result.add " "
  if dayOfMonth < 10:
    result.add " "
    result.add $dayOfMonth
  else:
    result.add $dayOfMonth
  result.add " "
  result.add padTwo(hourValue)
  result.add ":"
  result.add padTwo(minuteValue)
  result.add ":"
  result.add padTwo(secondValue)
  result.add " "
  result.add $year
  return result

var outputBuffer: string
while true:
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  if scanPos >= inputData.len: break
  var encryptedValue = nextInt()
  var rootValue = powerMod(encryptedValue)
  var timeStamp = rootValue
  if timeStamp > lastPossibleSecond: timeStamp = cipherModulus - rootValue
  outputBuffer.add clockLine(timeStamp)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
