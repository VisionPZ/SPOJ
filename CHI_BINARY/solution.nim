const limbBits = 30
const limbBase = 1 shl 30
const limbMask = limbBase - 1
const flushBlockBytes = 1 shl 17

type BigNumber = seq[int]
type DivisionResult = tuple[quotient: BigNumber, remainder: BigNumber]

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let start = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  if start >= pos:
    return ""
  return data[start .. pos - 1]

proc normalizeNumber(value: var BigNumber) =
  while value.len > 1 and value[value.len - 1] == 0:
    value.setLen value.len - 1

proc fromBinaryText(text: string): BigNumber =
  result = @[0]
  for character in text:
    let bitValue = ord(character) - 48
    if bitValue != 0 and bitValue != 1:
      continue
    var carry = bitValue
    for index in 0 ..< result.len:
      let combined = result[index] * 2 + carry
      result[index] = combined and limbMask
      carry = combined shr limbBits
    if carry > 0:
      result.add carry
  normalizeNumber result

proc bitLength(value: BigNumber): int =
  let topLimb = value[value.len - 1]
  var topBits = 0
  var probe = topLimb
  while probe > 0:
    probe = probe shr 1
    topBits += 1
  return (value.len - 1) * limbBits + topBits

proc compareNumbers(first: BigNumber, second: BigNumber): int =
  if first.len != second.len:
    if first.len > second.len:
      return 1
    return -1
  for index in countdown(first.len - 1, 0):
    if first[index] != second[index]:
      if first[index] > second[index]:
        return 1
      return -1
  return 0

proc addNumbers(first: BigNumber, second: BigNumber): BigNumber =
  result = @[]
  var carry = 0
  var longest = first.len
  if second.len > longest:
    longest = second.len
  for index in 0 ..< longest:
    var total = carry
    if index < first.len:
      total += first[index]
    if index < second.len:
      total += second[index]
    result.add total and limbMask
    carry = total shr limbBits
  if carry > 0:
    result.add carry
  normalizeNumber result

proc subtractNumbers(first: BigNumber, second: BigNumber): BigNumber =
  result = @[]
  var borrow = 0
  for index in 0 ..< first.len:
    var current = first[index] - borrow
    if index < second.len:
      current -= second[index]
    if current < 0:
      current += limbBase
      borrow = 1
    else:
      borrow = 0
    result.add current
  normalizeNumber result

proc multiplyNumbers(first: BigNumber, second: BigNumber): BigNumber =
  result = newSeq[int](first.len + second.len)
  for firstIndex in 0 ..< first.len:
    var carry = 0
    for secondIndex in 0 ..< second.len:
      let target = firstIndex + secondIndex
      let combined = result[target] + first[firstIndex] * second[secondIndex] + carry
      result[target] = combined and limbMask
      carry = combined shr limbBits
    var target = firstIndex + second.len
    while carry > 0:
      let combined = result[target] + carry
      result[target] = combined and limbMask
      carry = combined shr limbBits
      target += 1
  normalizeNumber result

proc powerOfTwo(exponent: int): BigNumber =
  let limbIndex = exponent div limbBits
  result = newSeq[int](limbIndex + 1)
  result[limbIndex] = 1 shl (exponent mod limbBits)

proc divideNumbers(dividend: BigNumber, divisor: BigNumber): DivisionResult =
  result.quotient = newSeq[int](dividend.len + 1)
  result.remainder = @[0]
  let totalBits = bitLength(dividend)
  for bitIndex in countdown(totalBits - 1, 0):
    var carry = (dividend[bitIndex div limbBits] shr (bitIndex mod limbBits)) and 1
    for index in 0 ..< result.remainder.len:
      let combined = result.remainder[index] * 2 + carry
      result.remainder[index] = combined and limbMask
      carry = combined shr limbBits
    if carry > 0:
      result.remainder.add carry
    normalizeNumber result.remainder
    if compareNumbers(result.remainder, divisor) >= 0:
      result.remainder = subtractNumbers(result.remainder, divisor)
      let limbIndex = bitIndex div limbBits
      result.quotient[limbIndex] = result.quotient[limbIndex] or (1 shl (bitIndex mod limbBits))
  normalizeNumber result.quotient

proc toBinaryText(value: BigNumber): string =
  if value.len == 1 and value[0] == 0:
    return "0"
  result = ""
  let topIndex = value.len - 1
  var mask = 1
  while mask <= value[topIndex]:
    mask = mask shl 1
  mask = mask shr 1
  while mask > 0:
    if (value[topIndex] and mask) != 0:
      result.add '1'
    else:
      result.add '0'
    mask = mask shr 1
  if topIndex > 0:
    for index in countdown(topIndex - 1, 0):
      mask = 1 shl (limbBits - 1)
      while mask > 0:
        if (value[index] and mask) != 0:
          result.add '1'
        else:
          result.add '0'
        mask = mask shr 1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let caseCount = fromBinaryText(nextToken(inputData, pos))[0]
var outputBuffer = ""
for _ in 0 ..< caseCount:
  let operatorToken = nextToken(inputData, pos)
  let firstToken = nextToken(inputData, pos)
  let secondToken = nextToken(inputData, pos)
  let operation = fromBinaryText(operatorToken)[0]
  let firstValue = fromBinaryText(firstToken)
  let secondValue = fromBinaryText(secondToken)
  case operation
  of 0:
    if compareNumbers(firstValue, secondValue) > 0:
      outputBuffer.add '1'
    else:
      outputBuffer.add '0'
  of 1:
    outputBuffer.add toBinaryText(addNumbers(firstValue, secondValue))
  of 2:
    if compareNumbers(firstValue, secondValue) >= 0:
      outputBuffer.add toBinaryText(subtractNumbers(firstValue, secondValue))
    else:
      var larger = firstValue
      if compareNumbers(secondValue, larger) > 0:
        larger = secondValue
      let shiftAmount = bitLength(larger)
      let wrapped = addNumbers(firstValue, powerOfTwo(shiftAmount))
      outputBuffer.add toBinaryText(subtractNumbers(wrapped, secondValue))
  of 3:
    outputBuffer.add toBinaryText(multiplyNumbers(firstValue, secondValue))
  of 4:
    if secondValue.len == 1 and secondValue[0] == 0:
      outputBuffer.add "0 0"
    else:
      let division = divideNumbers(firstValue, secondValue)
      outputBuffer.add toBinaryText(division.quotient)
      outputBuffer.add ' '
      outputBuffer.add toBinaryText(division.remainder)
  else:
    discard
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
