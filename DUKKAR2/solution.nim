const flushBlockBytes = 1 shl 17
const answerModulus: int64 = 1000000007
const inverseOfTwo: int64 = 500000004

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

let testCaseCount = nextInt(inputData, scanPos)
for testCase in 0 .. testCaseCount - 1:
  let primeBase = nextInt(inputData, scanPos)
  let digitCount = nextInt(inputData, scanPos)
  var baseDigits = newSeq[int](digitCount)
  for digitIndex in 0 .. digitCount - 1:
    baseDigits[digitIndex] = nextInt(inputData, scanPos)
  let baseModulo = int64(primeBase) mod answerModulus
  let basePlusOneModulo = (int64(primeBase) + 1) mod answerModulus
  let fullBlockSum = baseModulo * basePlusOneModulo mod answerModulus * inverseOfTwo mod answerModulus
  var blockPowers = newSeq[int64](digitCount)
  blockPowers[0] = 1
  for powerIndex in 1 .. digitCount - 1:
    blockPowers[powerIndex] = blockPowers[powerIndex - 1] * fullBlockSum mod answerModulus
  var nondivisibleSum: int64 = 0
  var higherProduct: int64 = 1
  var position = digitCount - 1
  while position >= 0:
    let digitModulo = int64(baseDigits[position]) mod answerModulus
    let digitPlusOne = (digitModulo + 1) mod answerModulus
    let smallerDigitsSum = digitModulo * digitPlusOne mod answerModulus * inverseOfTwo mod answerModulus
    nondivisibleSum = (nondivisibleSum + higherProduct * smallerDigitsSum mod answerModulus * blockPowers[position]) mod answerModulus
    higherProduct = higherProduct * digitPlusOne mod answerModulus
    position -= 1
  var valueModulo: int64 = 0
  position = digitCount - 1
  while position >= 0:
    valueModulo = (valueModulo * baseModulo + int64(baseDigits[position]) mod answerModulus) mod answerModulus
    position -= 1
  let totalEntries = valueModulo * ((valueModulo + 1) mod answerModulus) mod answerModulus * inverseOfTwo mod answerModulus
  let answer = (totalEntries - nondivisibleSum + answerModulus) mod answerModulus
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
