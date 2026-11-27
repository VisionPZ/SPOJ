import strutils
const flushBlockBytes = 1 shl 17

proc readInputStream(): string =
  var inputData = ""
  var line: string
  while readLine(stdin, line):
    inputData.add line
    inputData.add "\n"
  return inputData

proc sliceBetween(text: string, i: int, j: int): string =
  if j <= i: return ""
  return text[i .. j - 1]

proc nextToken(inputData: string, i: var int): string =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var j = i
  while i < inputData.len and inputData[i] > ' ': i = i + 1
  if i == j: return ""
  return sliceBetween(inputData, j, i)

proc dropLeadingZeros(digits: string): string =
  var i = 0
  while i < digits.len - 1 and digits[i] == '0': i = i + 1
  return sliceBetween(digits, i, digits.len)

proc reverseDigits(reversed: string): string =
  var answer = newString(reversed.len)
  var i = reversed.len - 1
  var j = 0
  while i >= 0:
    answer[j] = reversed[i]
    i = i - 1
    j = j + 1
  return answer

proc addDecimal(first, second: string): string =
  var i = first.len - 1
  var j = second.len - 1
  var carryIndex = 0
  var reversed: string
  while i >= 0 or j >= 0 or carryIndex > 0:
    var digitSum = carryIndex
    if i >= 0:
      digitSum = digitSum + int(first[i]) - 48
      i = i - 1
    if j >= 0:
      digitSum = digitSum + int(second[j]) - 48
      j = j - 1
    reversed.add char(48 + digitSum mod 10)
    carryIndex = digitSum div 10
  var answer = reverseDigits(reversed)
  return answer

proc subtractDecimal(first, second: string): string =
  var i = first.len - 1
  var j = second.len - 1
  var borrowIndex = 0
  var reversed: string
  while i >= 0:
    var digitDiff = int(first[i]) - 48 - borrowIndex
    if j >= 0: digitDiff = digitDiff - (int(second[j]) - 48)
    if digitDiff < 0:
      digitDiff = digitDiff + 10
      borrowIndex = 1
    else:
      borrowIndex = 0
    reversed.add char(48 + digitDiff)
    i = i - 1
    if j >= 0: j = j - 1
  return dropLeadingZeros(reverseDigits(reversed))

proc halveDecimal(digits: string): string =
  var i = 0
  var remainder = 0
  var quotient: string
  while i < digits.len:
    var dividend = remainder * 10 + (int(digits[i]) - 48)
    quotient.add char(48 + dividend div 2)
    remainder = dividend mod 2
    i = i + 1
  return dropLeadingZeros(quotient)

var inputData = readInputStream()
var i = 0
var outputBuffer: string
while true:
  var applesTotal = nextToken(inputData, i)
  if applesTotal.len == 0: break
  var applesMore = nextToken(inputData, i)
  outputBuffer.add halveDecimal(addDecimal(applesTotal, applesMore))
  outputBuffer.add "\n"
  outputBuffer.add halveDecimal(subtractDecimal(applesTotal, applesMore))
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
