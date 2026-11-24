{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const digitBase = 10
const trialFactor = 20
const maxTrialDigit = 9
const rootStart = 500
const remainderStart = 1000
const limbLimit = 1001

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int, start: var int, finish: var int) =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  start = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  finish = pos

proc parseCount(data: string, start: int, finish: int): int =
  var value = 0
  for k in start..<finish:
    value = value * digitBase + int(data[k]) - firstDigitValue
  return value

var remainderBuf: array[0..limbLimit - 1, int]
var rootBuf: array[0..rootStart, int]
var trialBuf: array[0..limbLimit - 1, int]
var productBuf: array[0..limbLimit - 1, int]
var chosenBuf: array[0..limbLimit - 1, int]

proc squareRoot(data: string, start: int, finish: int): string =
  var remOffset = remainderStart
  var remLen = 0
  var rootOffset = rootStart
  var rootLen = 0
  var pairPos = start
  if (finish - start) mod 2 == 1:
    pairPos -= 1
  while pairPos < finish:
    var pairValue = 0
    if pairPos >= start:
      pairValue = int(data[pairPos]) - firstDigitValue
    if pairPos + 1 < finish:
      pairValue = pairValue * digitBase + int(data[pairPos + 1]) - firstDigitValue
    remOffset -= 2
    remainderBuf[remOffset] = pairValue mod digitBase
    remainderBuf[remOffset + 1] = pairValue div digitBase
    remLen += 2
    while remLen > 0 and remainderBuf[remOffset + remLen - 1] == 0:
      remLen -= 1

    var baseLen = 0
    var carry = 0
    for k in 0..<rootLen:
      let value = rootBuf[rootOffset + k] * trialFactor + carry
      trialBuf[baseLen] = value mod digitBase
      baseLen += 1
      carry = value div digitBase
    while carry > 0:
      trialBuf[baseLen] = carry mod digitBase
      baseLen += 1
      carry = carry div digitBase

    var chosenDigit = 0
    var chosenLen = 0
    for digit in countdown(maxTrialDigit, 0):
      var prodLen = 0
      carry = 0
      for k in 0..<baseLen:
        let value = trialBuf[k] * digit + carry
        productBuf[prodLen] = value mod digitBase
        prodLen += 1
        carry = value div digitBase
      while carry > 0:
        productBuf[prodLen] = carry mod digitBase
        prodLen += 1
        carry = carry div digitBase
      var extra = digit * digit
      var k = 0
      while extra > 0:
        if k == prodLen:
          productBuf[prodLen] = 0
          prodLen += 1
        let value = productBuf[k] + extra
        productBuf[k] = value mod digitBase
        extra = value div digitBase
        k += 1
      while prodLen > 0 and productBuf[prodLen - 1] == 0:
        prodLen -= 1
      var order = 0
      if prodLen < remLen:
        order = -1
      elif prodLen > remLen:
        order = 1
      else:
        var m = prodLen - 1
        while m >= 0 and productBuf[m] == remainderBuf[remOffset + m]:
          m -= 1
        if m >= 0:
          order = (if productBuf[m] < remainderBuf[remOffset + m]: -1 else: 1)
      if order <= 0:
        chosenDigit = digit
        chosenLen = prodLen
        for k in 0..<prodLen:
          chosenBuf[k] = productBuf[k]
        break

    var borrow = 0
    for k in 0..<remLen:
      var value = remainderBuf[remOffset + k] - borrow
      if k < chosenLen:
        value -= chosenBuf[k]
      if value < 0:
        value += digitBase
        borrow = 1
      else:
        borrow = 0
      remainderBuf[remOffset + k] = value
    while remLen > 0 and remainderBuf[remOffset + remLen - 1] == 0:
      remLen -= 1

    rootOffset -= 1
    rootBuf[rootOffset] = chosenDigit
    rootLen += 1
    pairPos += 2

  result = newString(rootLen)
  for k in 0..<rootLen:
    result[rootLen - 1 - k] = char(rootBuf[rootOffset + k] + firstDigitValue)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var tokenStart = 0
var tokenFinish = 0
nextToken(inputData, scanPos, tokenStart, tokenFinish)
let caseCount = parseCount(inputData, tokenStart, tokenFinish)
for j in 0..<caseCount:
  nextToken(inputData, scanPos, tokenStart, tokenFinish)
  appendOutput(squareRoot(inputData, tokenStart, tokenFinish))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
