import strutils
const flushBlockBytes = 1 shl 17

proc readAllInput(): string =
  var inputData = ""
  var line: string
  while readLine(stdin, line):
    inputData.add line
    inputData.add "\n"
  return inputData

proc sliceBetween(text: string, startPos: int, endPos: int): string =
  if endPos <= startPos: return ""
  return text[startPos .. endPos - 1]

proc nextToken(inputData: string, scanPos: var int): string =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var tokenStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ': scanPos = scanPos + 1
  if scanPos == tokenStart: return ""
  return sliceBetween(inputData, tokenStart, scanPos)

proc dropLeadingZeros(digits: string): string =
  var walkPos = 0
  while walkPos < digits.len - 1 and digits[walkPos] == '0': walkPos = walkPos + 1
  return sliceBetween(digits, walkPos, digits.len)

proc reverseDigits(reversed: string): string =
  var answer = newString(reversed.len)
  var readIndex = reversed.len - 1
  var writeIndex = 0
  while readIndex >= 0:
    answer[writeIndex] = reversed[readIndex]
    readIndex = readIndex - 1
    writeIndex = writeIndex + 1
  return answer

proc addDecimal(first, second: string): string =
  var leftIndex = first.len - 1
  var rightIndex = second.len - 1
  var carryIndex = 0
  var reversed: string
  while leftIndex >= 0 or rightIndex >= 0 or carryIndex > 0:
    var digitSum = carryIndex
    if leftIndex >= 0:
      digitSum = digitSum + int(first[leftIndex]) - 48
      leftIndex = leftIndex - 1
    if rightIndex >= 0:
      digitSum = digitSum + int(second[rightIndex]) - 48
      rightIndex = rightIndex - 1
    reversed.add char(48 + digitSum mod 10)
    carryIndex = digitSum div 10
  var answer = reverseDigits(reversed)
  return answer

proc subtractDecimal(first, second: string): string =
  var leftIndex = first.len - 1
  var rightIndex = second.len - 1
  var borrowIndex = 0
  var reversed: string
  while leftIndex >= 0:
    var digitDiff = int(first[leftIndex]) - 48 - borrowIndex
    if rightIndex >= 0: digitDiff = digitDiff - (int(second[rightIndex]) - 48)
    if digitDiff < 0:
      digitDiff = digitDiff + 10
      borrowIndex = 1
    else:
      borrowIndex = 0
    reversed.add char(48 + digitDiff)
    leftIndex = leftIndex - 1
    if rightIndex >= 0: rightIndex = rightIndex - 1
  return dropLeadingZeros(reverseDigits(reversed))

proc halveDecimal(digits: string): string =
  var scanPos = 0
  var remainder = 0
  var quotient: string
  while scanPos < digits.len:
    var dividend = remainder * 10 + (int(digits[scanPos]) - 48)
    quotient.add char(48 + dividend div 2)
    remainder = dividend mod 2
    scanPos = scanPos + 1
  return dropLeadingZeros(quotient)

var inputData = readAllInput()
var scanPos = 0
var outputBuffer: string
while true:
  var applesTotal = nextToken(inputData, scanPos)
  if applesTotal.len == 0: break
  var applesMore = nextToken(inputData, scanPos)
  outputBuffer.add halveDecimal(addDecimal(applesTotal, applesMore))
  outputBuffer.add "\n"
  outputBuffer.add halveDecimal(subtractDecimal(applesTotal, applesMore))
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
