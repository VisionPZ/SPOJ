const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const maxSteps = 999

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc addDigits(target: var seq[int], source: seq[int]) =
  var carry = 0
  var digitIndex = 0
  while digitIndex < source.len:
    if digitIndex >= target.len:
      target.add 0
    let digitTotal = target[digitIndex] + source[digitIndex] + carry
    target[digitIndex] = digitTotal mod 10
    carry = digitTotal div 10
    digitIndex += 1
  while carry > 0:
    if digitIndex >= target.len:
      target.add 0
    let digitTotal = target[digitIndex] + carry
    target[digitIndex] = digitTotal mod 10
    carry = digitTotal div 10
    digitIndex += 1

proc doubleDigits(target: var seq[int]) =
  var carry = 0
  var digitIndex = 0
  while digitIndex < target.len:
    let digitTotal = target[digitIndex] * 2 + carry
    target[digitIndex] = digitTotal mod 10
    carry = digitTotal div 10
    digitIndex += 1
  if carry > 0:
    target.add carry

proc digitsToString(digits: seq[int]): string =
  var text = ""
  var digitIndex = digits.len
  while digitIndex > 0:
    digitIndex -= 1
    text.add chr(firstDigitValue + digits[digitIndex])
  return text

var answerTable = newSeq[string](maxSteps + 1)
var powerOfTwo: seq[int] = @[1]
var evenAnswer: seq[int] = @[1]
var oddAnswer: seq[int] = @[0]
answerTable[1] = "0"
answerTable[2] = "1"
for stepCount in 3 .. maxSteps:
  var currentAnswer: seq[int]
  if stepCount mod 2 == 0:
    currentAnswer = evenAnswer
    addDigits(currentAnswer, powerOfTwo)
    evenAnswer = currentAnswer
  else:
    currentAnswer = oddAnswer
    addDigits(currentAnswer, powerOfTwo)
    oddAnswer = currentAnswer
  answerTable[stepCount] = digitsToString(currentAnswer)
  doubleDigits(powerOfTwo)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let stepCount = nextInt(inputData, scanPos)
  if stepCount >= 1 and stepCount <= maxSteps:
    appendOutput(answerTable[stepCount])
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
