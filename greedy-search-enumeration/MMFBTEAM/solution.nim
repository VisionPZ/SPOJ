proc readStreamBytes(): string =
  var res = ""
  var chunk = newString(1 shl 16)
  while true:
    let got = readBuffer(stdin, addr chunk[0], chunk.len)
    if got <= 0:
      break
    let oldLen = res.len
    res.setLen(oldLen + got)
    copyMem(addr res[oldLen], addr chunk[0], got)
  return res

const firstDigitValue = 48
const answerModulus = 1000000007
const quarterModulus = 250000002
const chunkBase = 100000
const maxChunks = 7
const flushBlockBytes = 1 shl 16

var inputData = readStreamBytes()

proc powerMod(base: int64, exponent: int64): int64 =
  var productValue: int64 = 1
  var factor = base
  var power = exponent
  while power > 0:
    if (power and 1) == 1:
      productValue = productValue * factor mod int64(answerModulus)
    factor = factor * factor mod int64(answerModulus)
    power = power div 2
  return productValue

var remainders: array[0..maxChunks, array[0..chunkBase - 1, int32]]
var powers: array[0..maxChunks, array[0..chunkBase - 1, int32]]

var remainderStep: int64 = 1
var powerStep: int64 = 2
for j in 0 .. maxChunks:
  var remainderValue: int64 = 0
  var powerValue: int64 = 1
  for c in 0 .. chunkBase - 1:
    remainders[j][c] = int32(remainderValue)
    powers[j][c] = int32(powerValue)
    remainderValue += remainderStep
    if remainderValue >= int64(answerModulus):
      remainderValue -= int64(answerModulus)
    powerValue = powerValue * powerStep mod int64(answerModulus)
  remainderStep = remainderStep * int64(chunkBase) mod int64(answerModulus)
  powerStep = powerMod(powerStep, int64(chunkBase))

var outputBuffer = newString(flushBlockBytes)
var outputLength = 0
var numberDigits: array[0..15, byte]

proc putNumber(v: int64) =
  if outputLength + 16 > flushBlockBytes:
    stdout.write outputBuffer[0 ..< outputLength]
    outputLength = 0
  var x = v
  var k = 0
  if x == 0:
    numberDigits[0] = byte(firstDigitValue)
    k = 1
  else:
    while x > 0:
      numberDigits[k] = byte(firstDigitValue) + byte(x mod 10)
      x = x div 10
      k += 1
  while k > 0:
    k -= 1
    outputBuffer[outputLength] = char(numberDigits[k])
    outputLength += 1
  outputBuffer[outputLength] = '\n'
  outputLength += 1

var scanPos = 0
let inputLength = inputData.len

while true:
  while scanPos < inputLength and inputData[scanPos] <= ' ':
    scanPos += 1
  if scanPos >= inputLength:
    break
  var tokenEnd = scanPos
  while tokenEnd < inputLength and inputData[tokenEnd] > ' ':
    tokenEnd += 1
  scanPos = tokenEnd
  var readPos = tokenEnd - 1
  var nonzero = false
  var valueMod: int64 = 0
  var powerValue: int64 = 1
  var chunkIndex = 0
  while readPos >= 0 and inputData[readPos] > ' ':
    var chunk: int32 = 0
    var multiplier: int32 = 1
    var taken = 0
    while taken < 5 and readPos >= 0 and inputData[readPos] > ' ':
      let digit = byte(inputData[readPos]) - byte(firstDigitValue)
      if digit != 0:
        nonzero = true
      chunk += int32(digit) * multiplier
      multiplier *= 10
      dec readPos
      inc taken
    valueMod += int64(remainders[chunkIndex][chunk])
    if valueMod >= int64(answerModulus):
      valueMod -= int64(answerModulus)
    powerValue = powerValue * int64(powers[chunkIndex][chunk]) mod int64(answerModulus)
    inc chunkIndex
  if not nonzero:
    break
  var previous = valueMod - 1
  if previous < 0:
    previous += int64(answerModulus)
  let orderedPairs = valueMod * previous mod int64(answerModulus)
  let doubling = powerValue * int64(quarterModulus) mod int64(answerModulus)
  putNumber(orderedPairs * doubling mod int64(answerModulus))

stdout.write outputBuffer[0 ..< outputLength]
