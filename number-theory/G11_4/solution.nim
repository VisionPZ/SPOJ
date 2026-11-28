const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0.int64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

var powersOfTen: array[12, int64]
powersOfTen[0] = 1
for exponent in 1..11:
  powersOfTen[exponent] = powersOfTen[exponent - 1] * 10

proc countThrough(limit: int64): array[10, int64] =
  for digit in 0..9:
    result[digit] = 0
  if limit < 1:
    return
  var boundDigits: array[12, int]
  var digitCount = 0
  var remaining = limit
  while remaining > 0:
    boundDigits[digitCount] = int(remaining mod 10)
    digitCount += 1
    remaining = remaining div 10
  for length in 1..<digitCount:
    for digit in 1..9:
      result[digit] += powersOfTen[length - 1]
    if length >= 2:
      for digit in 0..9:
        result[digit] += int64(length - 1) * 9 * powersOfTen[length - 2]
  for position in 0..<digitCount:
    let remainingPositions = digitCount - position - 1
    let currentDigit = boundDigits[digitCount - 1 - position]
    let smallestDigit = if position == 0: 1 else: 0
    for smallerDigit in smallestDigit..<currentDigit:
      result[smallerDigit] += powersOfTen[remainingPositions]
      if remainingPositions >= 1:
        for digit in 0..9:
          result[digit] += int64(remainingPositions) * powersOfTen[remainingPositions - 1]
    let suffixValue = limit mod powersOfTen[remainingPositions]
    result[currentDigit] += suffixValue + 1

var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let lowerBound = nextNumber(inputData, scanPos)
  let upperBound = nextNumber(inputData, scanPos)
  if lowerBound == 0 and upperBound == 0: break
  let before = countThrough(lowerBound - 1)
  let through = countThrough(upperBound)
  for digit in 0..9:
    if digit > 0:
      appendOutput(" ")
    appendOutput($(through[digit] - before[digit]))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
