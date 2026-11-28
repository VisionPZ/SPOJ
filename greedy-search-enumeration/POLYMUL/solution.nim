const flushBlockBytes = 1 shl 17
const firstModulus = 998244353'i64
const secondModulus = 1004535809'i64
const primitiveRoot = 3'i64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc powerMod(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var basePart = baseValue mod modulus
  var exponentPart = exponentValue
  result = 1'i64
  while exponentPart > 0:
    if exponentPart mod 2 == 1:
      result = result * basePart mod modulus
    basePart = basePart * basePart mod modulus
    exponentPart = exponentPart div 2

proc transform(values: var seq[int64], length: int, invertTransform: bool, modulus: int64) =
  var reverseIndex = 0
  for index in 1 .. length - 1:
    var bit = length shr 1
    while (reverseIndex and bit) != 0:
      reverseIndex = reverseIndex xor bit
      bit = bit shr 1
    reverseIndex = reverseIndex or bit
    if index < reverseIndex:
      swap(values[index], values[reverseIndex])
  var blockLength = 2
  while blockLength <= length:
    var rootStep = powerMod(primitiveRoot, (modulus - 1) div blockLength, modulus)
    if invertTransform:
      rootStep = powerMod(rootStep, modulus - 2, modulus)
    var blockStart = 0
    while blockStart < length:
      var twist = 1'i64
      let halfBlock = blockLength shr 1
      for offset in 0 .. halfBlock - 1:
        let leftValue = values[blockStart + offset]
        let rightValue = values[blockStart + offset + halfBlock] * twist mod modulus
        var combined = (leftValue + rightValue) mod modulus
        var difference = (leftValue - rightValue) mod modulus
        if difference < 0:
          difference = difference + modulus
        values[blockStart + offset] = combined
        values[blockStart + offset + halfBlock] = difference
        twist = twist * rootStep mod modulus
      blockStart = blockStart + blockLength
    blockLength = blockLength shl 1
  if invertTransform:
    let lengthInverse = powerMod(int64(length), modulus - 2, modulus)
    for index in 0 .. length - 1:
      values[index] = values[index] * lengthInverse mod modulus

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
let firstInverse = powerMod(firstModulus mod secondModulus, secondModulus - 2, secondModulus)
for caseIndex in 0 .. caseCount - 1:
  let degree = int(nextInt(inputData, scanPos))
  var firstPoly = newSeq[int64](degree + 1)
  var secondPoly = newSeq[int64](degree + 1)
  for coefficientIndex in 0 .. degree:
    firstPoly[coefficientIndex] = nextInt(inputData, scanPos)
  for coefficientIndex in 0 .. degree:
    secondPoly[coefficientIndex] = nextInt(inputData, scanPos)
  var transformLength = 1
  while transformLength < 2 * degree + 1:
    transformLength = transformLength shl 1
  var firstPart = newSeq[int64](transformLength)
  var secondPart = newSeq[int64](transformLength)
  for coefficientIndex in 0 .. degree:
    firstPart[coefficientIndex] = firstPoly[coefficientIndex] mod firstModulus
    secondPart[coefficientIndex] = secondPoly[coefficientIndex] mod firstModulus
  transform(firstPart, transformLength, false, firstModulus)
  transform(secondPart, transformLength, false, firstModulus)
  for coefficientIndex in 0 .. transformLength - 1:
    firstPart[coefficientIndex] = firstPart[coefficientIndex] * secondPart[coefficientIndex] mod firstModulus
  transform(firstPart, transformLength, true, firstModulus)
  var secondResult = newSeq[int64](transformLength)
  secondPart = newSeq[int64](transformLength)
  for coefficientIndex in 0 .. degree:
    secondResult[coefficientIndex] = firstPoly[coefficientIndex] mod secondModulus
    secondPart[coefficientIndex] = secondPoly[coefficientIndex] mod secondModulus
  transform(secondResult, transformLength, false, secondModulus)
  transform(secondPart, transformLength, false, secondModulus)
  for coefficientIndex in 0 .. transformLength - 1:
    secondResult[coefficientIndex] = secondResult[coefficientIndex] * secondPart[coefficientIndex] mod secondModulus
  transform(secondResult, transformLength, true, secondModulus)
  for coefficientIndex in 0 .. 2 * degree:
    let residueGap = (secondResult[coefficientIndex] - firstPart[coefficientIndex]) mod secondModulus
    var liftFactor = 0'i64
    if residueGap < 0:
      liftFactor = (residueGap + secondModulus) * firstInverse mod secondModulus
    else:
      liftFactor = residueGap * firstInverse mod secondModulus
    let exactValue = firstPart[coefficientIndex] + firstModulus * liftFactor
    if coefficientIndex > 0:
      outputBuffer.add ' '
    appendOutput($exactValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
