const flushBlockBytes = 1 shl 17
const decimalBase = 1000000000
const limbCapacity = 6

type BigLimbArray = array[0 .. limbCapacity - 1, int64]

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

proc addProduct(accumulator: var BigLimbArray, leftFactor: int64, rightFactor: int64, extraTerm: int64) =
  var leftDigits: array[0 .. 2, int64]
  var rightDigits: array[0 .. 2, int64]
  var leftLength = 0
  var rightLength = 0
  var remaining = leftFactor
  while remaining > 0:
    leftDigits[leftLength] = remaining mod decimalBase
    remaining = remaining div decimalBase
    leftLength += 1
  remaining = rightFactor
  while remaining > 0:
    rightDigits[rightLength] = remaining mod decimalBase
    remaining = remaining div decimalBase
    rightLength += 1
  for leftIndex in 0 .. leftLength - 1:
    var innerCarry = int64(0)
    for rightIndex in 0 .. rightLength - 1:
      let limbPosition = leftIndex + rightIndex
      let limbValue = accumulator[limbPosition] + leftDigits[leftIndex] * rightDigits[rightIndex] + innerCarry
      accumulator[limbPosition] = limbValue mod decimalBase
      innerCarry = limbValue div decimalBase
    var carryPosition = leftIndex + rightLength
    while innerCarry > 0:
      let carryValue = accumulator[carryPosition] + innerCarry
      accumulator[carryPosition] = carryValue mod decimalBase
      innerCarry = carryValue div decimalBase
      carryPosition += 1
  var carryOver = int64(0)
  var extraRemaining = extraTerm
  var extraPosition = 0
  while extraRemaining > 0 or carryOver > 0:
    let extraDigit = extraRemaining mod decimalBase
    extraRemaining = extraRemaining div decimalBase
    let limbValue = accumulator[extraPosition] + extraDigit + carryOver
    accumulator[extraPosition] = limbValue mod decimalBase
    carryOver = limbValue div decimalBase
    extraPosition += 1

proc appendBigNumber(accumulator: BigLimbArray) =
  var highest = limbCapacity - 1
  while highest > 0 and accumulator[highest] == 0:
    highest -= 1
  appendOutput($accumulator[highest])
  var position = highest - 1
  while position >= 0:
    var limbText = $accumulator[position]
    while limbText.len < 9:
      limbText = "0" & limbText
    appendOutput(limbText)
    position -= 1

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let primeValue = int64(nextInt(inputData, scanPos))
  let factorialLimit = int64(nextInt(inputData, scanPos))
  var answer: BigLimbArray
  for limbIndex in 0 .. limbCapacity - 1:
    answer[limbIndex] = 0
  var primePower = primeValue
  while primePower <= factorialLimit:
    let quotient = factorialLimit div primePower
    let remainder = factorialLimit mod primePower
    let pairedValue = primePower * quotient
    let neighborValue = quotient - 1
    var halfValue = int64(0)
    var otherValue = int64(0)
    if (quotient and 1'i64) == 0:
      halfValue = pairedValue div 2
      otherValue = neighborValue
    else:
      halfValue = neighborValue div 2
      otherValue = pairedValue
    addProduct(answer, halfValue, otherValue, (remainder + 1) * quotient)
    if primePower > factorialLimit div primeValue:
      break
    primePower = primePower * primeValue
  appendBigNumber(answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
