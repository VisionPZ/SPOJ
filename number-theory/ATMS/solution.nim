{.checks: off.}
{.optimization: speed.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const digitCapacity = 40
const bitCapacity = 128
const lastAtmIndex = 99

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
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextDigits(data: string, position: var int, digits: var array[0..digitCapacity - 1, int]) =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var tokenEnd = position
  while tokenEnd < data.len and data[tokenEnd] >= '0' and data[tokenEnd] <= '9':
    tokenEnd += 1
  for i in 0..<digitCapacity:
    digits[i] = 0
  var digitIndex = 0
  var k = tokenEnd - 1
  while k >= position:
    digits[digitIndex] = int(data[k]) - firstDigitValue
    digitIndex += 1
    k -= 1
  position = tokenEnd

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc digitsAreZero(digits: array[0..digitCapacity - 1, int]): bool =
  for i in 0..<digitCapacity:
    if digits[i] != 0:
      return false
  return true

proc appendAtmList(valueDigits: array[0..digitCapacity - 1, int], negative: bool) =
  var workDigits = valueDigits
  var signNegative = negative
  var usedBits: array[0..bitCapacity - 1, bool]
  var highestBit = -1
  var bitIndex = 0
  while not digitsAreZero(workDigits):
    let oddDigit = workDigits[0] mod 2
    if oddDigit == 1:
      usedBits[bitIndex] = true
      highestBit = bitIndex
    if signNegative:
      if oddDigit == 1:
        var digitIndex = 0
        while true:
          let raised = workDigits[digitIndex] + 1
          workDigits[digitIndex] = raised mod 10
          if raised < 10:
            break
          digitIndex += 1
    elif oddDigit == 1:
      var digitIndex = 0
      while workDigits[digitIndex] == 0:
        workDigits[digitIndex] = 9
        digitIndex += 1
      workDigits[digitIndex] -= 1
    var carry = 0
    for i in countdown(digitCapacity - 1, 0):
      let current = carry * 10 + workDigits[i]
      workDigits[i] = current div 2
      carry = current mod 2
    signNegative = not signNegative
    bitIndex += 1
  if highestBit > lastAtmIndex:
    appendOutput("No")
  else:
    var firstNumber = true
    for i in countdown(highestBit, 0):
      if usedBits[i]:
        if not firstNumber:
          outputBuffer.add ' '
        appendOutput($(i))
        firstNumber = false
  outputBuffer.add '\n'

let caseCount = nextInt(inputData, scanPos)
var valueDigits: array[0..digitCapacity - 1, int]
for caseIndex in 0..<caseCount:
  nextDigits(inputData, scanPos, valueDigits)
  appendAtmList(valueDigits, false)
  appendAtmList(valueDigits, true)

stdout.write outputBuffer
outputBuffer.setLen 0
