const flushBlockBytes = 1 shl 17
const limbBase = 1 shl 32
const limbMask = limbBase - 1
const chunkLimbs = 512
const decimalGroupBase = 1000000000

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

proc powerLimbs(baseValue: int, exponent: int): seq[int] =
  result = @[1]
  for exponentStep in 0 .. exponent - 1:
    var carry: int64 = 0
    for limbIndex in 0 .. result.len - 1:
      let product = int64(result[limbIndex]) * int64(baseValue) + carry
      result[limbIndex] = int(product and int64(limbMask))
      carry = product shr 32
    while carry > 0:
      result.add(int(carry and int64(limbMask)))
      carry = carry shr 32

proc digitSumDecimal(firstPower: seq[int], secondPower: seq[int]): string =
  let combinedLength = max(firstPower.len, secondPower.len)
  var combined = newSeq[int](combinedLength)
  for limbIndex in 0 .. combinedLength - 1:
    var firstLimb = 0
    var secondLimb = 0
    if limbIndex < firstPower.len:
      firstLimb = firstPower[limbIndex]
    if limbIndex < secondPower.len:
      secondLimb = secondPower[limbIndex]
    combined[limbIndex] = firstLimb xor secondLimb
  let chunkCount = (combinedLength + chunkLimbs - 1) div chunkLimbs
  var sumLimbs = newSeq[int](chunkCount * chunkLimbs + 2)
  for chunkIndex in 0 .. chunkCount - 1:
    var carry: int64 = 0
    for limbIndex in 0 .. chunkLimbs - 1:
      let limbPosition = chunkIndex * chunkLimbs + limbIndex
      var addend = 0
      if limbPosition < combinedLength:
        addend = combined[limbPosition]
      let partial = int64(sumLimbs[limbIndex]) + int64(addend) + carry
      sumLimbs[limbIndex] = int(partial and int64(limbMask))
      carry = partial shr 32
    var carryIndex = chunkLimbs
    while carry > 0:
      let partial = int64(sumLimbs[carryIndex]) + carry
      sumLimbs[carryIndex] = int(partial and int64(limbMask))
      carry = partial shr 32
      carryIndex += 1
  var highestLimb = sumLimbs.len - 1
  while highestLimb > 0 and sumLimbs[highestLimb] == 0:
    highestLimb -= 1
  var decimalText = ""
  while highestLimb > 0 or sumLimbs[0] != 0:
    var remainder: int64 = 0
    for limbIndex in countdown(highestLimb, 0):
      let current = remainder * int64(limbBase) + int64(sumLimbs[limbIndex])
      sumLimbs[limbIndex] = int(current div int64(decimalGroupBase))
      remainder = current mod int64(decimalGroupBase)
    while highestLimb > 0 and sumLimbs[highestLimb] == 0:
      highestLimb -= 1
    if remainder == 0 and highestLimb == 0 and sumLimbs[0] == 0:
      break
    var groupText = $remainder
    while groupText.len < 9:
      groupText = "0" & groupText
    decimalText = groupText & decimalText
  var firstNonZero = 0
  while firstNonZero < decimalText.len and decimalText[firstNonZero] == '0':
    firstNonZero += 1
  if firstNonZero > 0:
    decimalText = decimalText[firstNonZero .. decimalText.len - 1]
  if decimalText == "":
    decimalText = "0"
  return decimalText

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let firstBase = nextInt(inputData, scanPos)
  let firstExponent = nextInt(inputData, scanPos)
  let secondBase = nextInt(inputData, scanPos)
  let secondExponent = nextInt(inputData, scanPos)
  let firstPower = powerLimbs(firstBase, firstExponent)
  let secondPower = powerLimbs(secondBase, secondExponent)
  appendOutput(digitSumDecimal(firstPower, secondPower))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
