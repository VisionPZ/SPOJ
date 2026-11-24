const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const maxDigitCount = 101

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var negative = false
  if i < inputData.len and inputData[i] == '-':
    negative = true
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - firstDigitValue
    i = i + 1
  if negative: return -value
  return value

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
var digits: array[maxDigitCount + 1, int]
for j in 1 .. caseCount:
  var currentReal = nextInt(inputData, i)
  var currentImag = nextInt(inputData, i)
  var baseReal = nextInt(inputData, i)
  var baseImag = nextInt(inputData, i)
  var baseNorm = baseReal * baseReal + baseImag * baseImag
  var largestDigit = 0
  while (largestDigit + 1) * (largestDigit + 1) < baseNorm: largestDigit = largestDigit + 1
  var digitCount = 0
  var failed = false
  if currentReal == 0 and currentImag == 0:
    digits[0] = 0
    digitCount = 1
  else:
    while true:
      var chosenDigit = -1
      var chosenReal = 0
      var chosenImag = 0
      for digit in 0 .. largestDigit:
        var remainderReal = (currentReal - digit) * baseReal + currentImag * baseImag
        var remainderImag = currentImag * baseReal - (currentReal - digit) * baseImag
        if remainderReal mod baseNorm == 0 and remainderImag mod baseNorm == 0:
          chosenDigit = digit
          chosenReal = remainderReal div baseNorm
          chosenImag = remainderImag div baseNorm
          break
      if chosenDigit < 0:
        failed = true
        break
      digits[digitCount] = chosenDigit
      digitCount = digitCount + 1
      if chosenReal == 0 and chosenImag == 0: break
      if digitCount >= maxDigitCount:
        failed = true
        break
      currentReal = chosenReal
      currentImag = chosenImag
  if failed:
    outputBuffer.add "The code cannot be decrypted.\n"
  else:
    var k = digitCount - 1
    while k >= 0:
      if k < digitCount - 1: outputBuffer.add ','
      outputBuffer.add $digits[k]
      k = k - 1
    outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
