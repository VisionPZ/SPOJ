const flushBlockBytes = 1 shl 17
const divisorValue = 11

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextDigitText(data: string, pos: var int): string =
  result = ""
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result.add data[pos]
    pos += 1

proc canonicalDigits(rawText: string): string =
  var start = 0
  while start < rawText.len - 1 and rawText[start] == '0':
    start += 1
  result = rawText[start .. rawText.len - 1]

proc subtractDigit(numberText: string, digitValue: int): string =
  var digits = newSeq[int](numberText.len)
  for index in 0 .. numberText.len - 1:
    digits[index] = int(numberText[index]) - 48
  var borrow = 0
  var position = digits.len - 1
  var difference = digits[position] - digitValue
  if difference < 0:
    difference += 10
    borrow = 1
  digits[position] = difference
  position -= 1
  while position >= 0 and borrow > 0:
    difference = digits[position] - borrow
    if difference < 0:
      difference += 10
      borrow = 1
    else:
      borrow = 0
    digits[position] = difference
    position -= 1
  var start = 0
  while start < digits.len - 1 and digits[start] == 0:
    start += 1
  result = ""
  for index in start .. digits.len - 1:
    result.add chr(digits[index] + 48)

proc isDivisibleByEleven(numberText: string): bool =
  var alternating = 0
  var position = 0
  var index = numberText.len - 1
  while index >= 0:
    let digitValue = int(numberText[index]) - 48
    if position mod 2 == 0:
      alternating += digitValue
    else:
      alternating -= digitValue
    position += 1
    index -= 1
  return alternating mod divisorValue == 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var caseCount = 0
while true:
  let rawNumber = nextDigitText(inputData, scanPos)
  if rawNumber.len == 0:
    break
  if rawNumber == "0":
    break
  let originalText = canonicalDigits(rawNumber)
  var stepLines: seq[string] = @[]
  stepLines.add originalText
  var remainingText = originalText
  while remainingText.len > 2:
    let lastDigit = int(remainingText[remainingText.len - 1]) - 48
    let truncatedText = canonicalDigits(remainingText[0 .. remainingText.len - 2])
    remainingText = subtractDigit(truncatedText, lastDigit)
    stepLines.add remainingText
  if caseCount > 0:
    appendOutput("\n")
  for stepText in stepLines:
    appendOutput(stepText)
    appendOutput("\n")
  if isDivisibleByEleven(remainingText):
    appendOutput("El numero " & originalText & " es divisible por 11.\n")
  else:
    appendOutput("El numero " & originalText & " no es divisible por 11.\n")
  caseCount += 1
if caseCount > 0:
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
