const flushBlockBytes = 1 shl 17
const digitBaseValue = 1000000000

proc normalizeDigits(digits: var seq[int32]) =
  while digits.len > 0 and digits[digits.len - 1] == 0:
    digits.setLen(digits.len - 1)
  if digits.len == 0:
    digits.add 0

proc multiplyBySmall(digits: var seq[int32], factor: int64) =
  var carryValue = 0.int64
  for digitIndex in 0 .. digits.len - 1:
    let productValue = int64(digits[digitIndex]) * factor + carryValue
    digits[digitIndex] = int32(productValue mod int64(digitBaseValue))
    carryValue = productValue div int64(digitBaseValue)
  while carryValue > 0:
    digits.add int32(carryValue mod int64(digitBaseValue))
    carryValue = carryValue div int64(digitBaseValue)

proc divideBySmall(digits: var seq[int32], divisor: int) =
  var remainderValue = 0.int64
  for digitIndex in countdown(digits.len - 1, 0):
    let currentValue = remainderValue * int64(digitBaseValue) + int64(digits[digitIndex])
    digits[digitIndex] = int32(currentValue div int64(divisor))
    remainderValue = currentValue mod int64(divisor)
  normalizeDigits(digits)

proc addBigNumbers(result: var seq[int32], other: seq[int32]) =
  if result.len < other.len:
    result.setLen(other.len)
  var carryValue = 0.int64
  for digitIndex in 0 .. other.len - 1:
    let sumValue = int64(result[digitIndex]) + int64(other[digitIndex]) + carryValue
    result[digitIndex] = int32(sumValue mod int64(digitBaseValue))
    carryValue = sumValue div int64(digitBaseValue)
  var extensionIndex = other.len
  while carryValue > 0:
    if extensionIndex >= result.len:
      result.add 0
    let sumValue = int64(result[extensionIndex]) + carryValue
    result[extensionIndex] = int32(sumValue mod int64(digitBaseValue))
    carryValue = sumValue div int64(digitBaseValue)
    extensionIndex += 1

proc multiplyBigNumbers(leftValue, rightValue: seq[int32]): seq[int32] =
  var productDigits = newSeq[int32](leftValue.len + rightValue.len + 2)
  for leftIndex in 0 .. leftValue.len - 1:
    var carryValue = 0.int64
    for rightIndex in 0 .. rightValue.len - 1:
      let productIndex = leftIndex + rightIndex
      let productValue = int64(productDigits[productIndex]) +
                         int64(leftValue[leftIndex]) * int64(rightValue[rightIndex]) + carryValue
      productDigits[productIndex] = int32(productValue mod int64(digitBaseValue))
      carryValue = productValue div int64(digitBaseValue)
    var productIndex = leftIndex + rightValue.len
    while carryValue > 0:
      let productValue = int64(productDigits[productIndex]) + carryValue
      productDigits[productIndex] = int32(productValue mod int64(digitBaseValue))
      carryValue = productValue div int64(digitBaseValue)
      productIndex += 1
  normalizeDigits(productDigits)
  return productDigits

proc digitsToString(digits: seq[int32]): string =
  var text = $digits[digits.len - 1]
  for digitIndex in countdown(digits.len - 2, 0):
    var blockText = $digits[digitIndex]
    while blockText.len < 9:
      blockText = "0" & blockText
    text.add blockText
  return text

proc binomialDigits(totalCount, chosenCount: int): seq[int32] =
  var resultDigits = @[1.int32]
  for stepValue in 1 .. chosenCount:
    multiplyBySmall(resultDigits, int64(totalCount - chosenCount + stepValue))
    divideBySmall(resultDigits, stepValue)
  return resultDigits

proc uniformPartitionDigits(groupTotal, groupSize: int): seq[int32] =
  var resultDigits = @[1.int32]
  let groupMultiple = groupTotal div groupSize
  var currentMultiple = 2
  while currentMultiple <= groupMultiple:
    let combinedDigits = binomialDigits(currentMultiple * groupSize - 1, groupSize - 1)
    resultDigits = multiplyBigNumbers(resultDigits, combinedDigits)
    currentMultiple += 1
  return resultDigits

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

let caseCount = nextInt(inputData, scanPos)
var totalSizes = newSeq[int](caseCount)
var largestSize = 0
for caseIndex in 0 .. caseCount - 1:
  let busCount = nextInt(inputData, scanPos)
  let busCapacity = nextInt(inputData, scanPos)
  let totalSize = busCount * busCapacity
  totalSizes[caseIndex] = totalSize
  if totalSize > largestSize:
    largestSize = totalSize

var cachedAnswers = newSeq[seq[int32]](largestSize + 1)
for caseIndex in 0 .. caseCount - 1:
  let totalSize = totalSizes[caseIndex]
  if cachedAnswers[totalSize].len == 0:
    var answerDigits = @[0.int32]
    for divisor in 1 .. totalSize:
      if totalSize mod divisor == 0:
        let termDigits = uniformPartitionDigits(totalSize, divisor)
        addBigNumbers(answerDigits, termDigits)
    cachedAnswers[totalSize] = answerDigits
  appendOutput(digitsToString(cachedAnswers[totalSize]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
