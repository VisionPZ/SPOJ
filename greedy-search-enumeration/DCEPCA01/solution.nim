const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc buildDynamicNumber(length, evenSeed: int): string =
  result = newString(length)
  for position in 0 .. length - 1:
    var digitValue = 4
    if position == 2:
      digitValue = evenSeed
    elif position >= 3 and (position mod 2) == 1:
      let stepIndex = (position - 3) div 2
      if stepIndex mod 2 == 0:
        digitValue = 7
      else:
        digitValue = 4
    elif position >= 4 and (position mod 2) == 0:
      let stepIndex = (position - 4) div 2
      if evenSeed == 4:
        if stepIndex mod 2 == 0:
          digitValue = 7
        else:
          digitValue = 4
      else:
        if stepIndex mod 2 == 0:
          digitValue = 4
        else:
          digitValue = 7
    result[position] = char(48 + digitValue)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberLength = nextInt(inputData, scanPos)
  let firstNumber = buildDynamicNumber(numberLength, 4)
  let secondNumber = buildDynamicNumber(numberLength, 7)
  var sumDigits = newString(numberLength + 1)
  var writePosition = numberLength
  var carry = 0
  var position = numberLength - 1
  while position >= 0:
    let digitTotal = int(firstNumber[position]) + int(secondNumber[position]) - 96 + carry
    sumDigits[writePosition] = char(48 + (digitTotal mod 10))
    carry = digitTotal div 10
    writePosition -= 1
    position -= 1
  if carry > 0:
    sumDigits[writePosition] = char(48 + carry)
    writePosition -= 1
  appendOutput(sumDigits[writePosition + 1 .. numberLength])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
