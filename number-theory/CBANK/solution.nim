const flushBlockBytes = 1 shl 17
const modulus = 1000000007
const inverseTwo = 500000004
const inverseSix = 166666668
const quartersPerRupee = 4
const quartersPerLargeCoin = 8
const quartersPerMediumCoin = 4

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

proc modMultiply(left, right: int64): int64 =
  return (left * right) mod int64(modulus)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let rupees = int64(nextInt(inputData, scanPos))
  let targetQuarters = rupees * quartersPerRupee
  let blockCount = targetQuarters div quartersPerLargeCoin
  let remainder = targetQuarters mod quartersPerLargeCoin
  let firstCoefficient = int64(remainder div quartersPerMediumCoin + 1)
  let secondCoefficient = firstCoefficient + int64((remainder mod quartersPerMediumCoin) div 2)
  let blockMod = blockCount mod int64(modulus)
  let nextBlockMod = (blockCount + 1) mod int64(modulus)
  let doubleBlockMod = (2 * blockCount + 1) mod int64(modulus)
  let pairProduct = modMultiply(blockMod, nextBlockMod)
  let linearSum = modMultiply(pairProduct, inverseTwo)
  let squareSum = modMultiply(modMultiply(pairProduct, doubleBlockMod), inverseSix)
  let firstPart = modMultiply(4, squareSum)
  let middlePart = modMultiply(modMultiply(2, firstCoefficient + secondCoefficient), linearSum)
  let lastPart = modMultiply(modMultiply(nextBlockMod, firstCoefficient), secondCoefficient)
  let answer = (firstPart + middlePart + lastPart) mod int64(modulus)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
