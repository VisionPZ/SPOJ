const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const smallestUsefulDigit = 2
const largestUsefulDigit = 9

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let targetProduct = nextInt(inputData, scanPos)
  if targetProduct == 0:
    appendOutput("10")
  elif targetProduct == 1:
    appendOutput("1")
  else:
    var remainingProduct = targetProduct
    var collectedDigits: array[23, char]
    var digitCount = 0
    var divisor = largestUsefulDigit
    while divisor >= smallestUsefulDigit:
      while remainingProduct mod divisor == 0:
        remainingProduct = remainingProduct div divisor
        collectedDigits[digitCount] = chr(divisor + firstDigitValue)
        digitCount += 1
      divisor -= 1
    if remainingProduct != 1:
      appendOutput("-1")
    else:
      var smallestInteger = ""
      for digitIndex in countdown(digitCount - 1, 0):
        smallestInteger.add collectedDigits[digitIndex]
      appendOutput(smallestInteger)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
