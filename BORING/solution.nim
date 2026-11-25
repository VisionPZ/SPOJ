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

proc multiplyMod(leftValue: int64, rightValue: int64, modulusValue: int64): int64 =
  if modulusValue < (1'i64 shl 32):
    let smallLeft = uint64(leftValue mod modulusValue)
    let smallRight = uint64(rightValue mod modulusValue)
    return int64((smallLeft * smallRight) mod uint64(modulusValue))
  let mask = 0xffffffff'u64
  let baseShift = 32'u64
  let firstLow = uint64(leftValue) and mask
  let firstHigh = uint64(leftValue) shr baseShift
  let secondLow = uint64(rightValue) and mask
  let secondHigh = uint64(rightValue) shr baseShift
  var product = [0'u64, 0'u64, 0'u64, 0'u64, 0'u64, 0'u64]
  for row in 0 .. 1:
    let rowValue = if row == 0: firstLow else: firstHigh
    var carry = 0'u64
    for column in 0 .. 1:
      let columnValue = if column == 0: secondLow else: secondHigh
      let combined = rowValue * columnValue + product[row + column] + carry
      product[row + column] = combined and mask
      carry = combined shr baseShift
    var position = row + 2
    while carry > 0'u64:
      let combined = product[position] + carry
      product[position] = combined and mask
      carry = combined shr baseShift
      position += 1
  let divisorLow = uint64(modulusValue) and mask
  let divisorHigh = uint64(modulusValue) shr baseShift
  let scale = (1'u64 shl baseShift) div (divisorHigh + 1'u64)
  let scaledFull = uint64(modulusValue) * scale
  let scaledLow = scaledFull and mask
  let scaledHigh = scaledFull shr baseShift
  var remainder = [0'u64, 0'u64, 0'u64, 0'u64, 0'u64, 0'u64, 0'u64]
  var scaleCarry = 0'u64
  for index in 0 .. 5:
    let combined = product[index] * scale + scaleCarry
    remainder[index] = combined and mask
    scaleCarry = combined shr baseShift
  remainder[6] = scaleCarry
  for shift in countdown(4, 0):
    let topPair = remainder[shift + 2] * (1'u64 shl baseShift) + remainder[shift + 1]
    var estimate = topPair div scaledHigh
    if estimate >= (1'u64 shl baseShift):
      estimate = (1'u64 shl baseShift) - 1'u64
    var productLow = estimate * scaledLow
    var productHigh = estimate * scaledHigh + (productLow shr baseShift)
    var productTop = productHigh shr baseShift
    var productMiddle = productHigh and mask
    var productBottom = productLow and mask
    while productTop > remainder[shift + 2] or
          (productTop == remainder[shift + 2] and
           (productMiddle > remainder[shift + 1] or
            (productMiddle == remainder[shift + 1] and productBottom > remainder[shift]))):
      estimate -= 1
      productLow = estimate * scaledLow
      productHigh = estimate * scaledHigh + (productLow shr baseShift)
      productTop = productHigh shr baseShift
      productMiddle = productHigh and mask
      productBottom = productLow and mask
    var borrow = 0'i64
    for index in 0 .. 2:
      let subValue = if index == 0: productBottom else:
                     (if index == 1: productMiddle else: productTop)
      var difference = int64(remainder[shift + index]) - int64(subValue) - borrow
      if difference < 0:
        difference += int64(1'u64 shl baseShift)
        borrow = 1
      else:
        borrow = 0
      remainder[shift + index] = uint64(difference)
  let scaledRemainder = remainder[1] * (1'u64 shl baseShift) + remainder[0]
  return int64(scaledRemainder div scale)

proc powerMod(baseValue: int64, exponentValue: int64, modulusValue: int64): int64 =
  var powerResult = 1'i64
  var baseCopy = baseValue mod modulusValue
  var exponentCopy = exponentValue
  while exponentCopy > 0:
    if (exponentCopy and 1'i64) != 0:
      powerResult = multiplyMod(powerResult, baseCopy, modulusValue)
    baseCopy = multiplyMod(baseCopy, baseCopy, modulusValue)
    exponentCopy = exponentCopy shr 1
  return powerResult

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let factorialIndex = int64(nextInt(inputData, scanPos))
  let primeModulus = int64(nextInt(inputData, scanPos))
  if factorialIndex >= primeModulus:
    appendOutput("0\n")
    continue
  let missingCount = primeModulus - 1 - factorialIndex
  var chunkProduct = 1'i64
  var factorialResidue = 1'i64
  var factorValue = 1'i64
  while factorValue <= missingCount:
    if chunkProduct <= high(int64) div factorValue:
      chunkProduct = chunkProduct * factorValue
    else:
      factorialResidue = multiplyMod(factorialResidue, chunkProduct, primeModulus)
      chunkProduct = factorValue
    factorValue += 1
  factorialResidue = multiplyMod(factorialResidue, chunkProduct, primeModulus)
  let inverseValue = powerMod(factorialResidue, primeModulus - 2, primeModulus)
  var answer = primeModulus - inverseValue
  if (missingCount and 1'i64) != 0:
    answer = inverseValue
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
