const flushBlockBytes = 1 shl 17
const limbBase: int64 = 1000000000
const maxDegree = 25

type BigNumber = object
  negative: bool
  limbs: seq[int64]

proc normalizeNumber(value: var BigNumber) =
  while value.limbs.len > 1 and value.limbs[value.limbs.len - 1] == 0:
    value.limbs.setLen(value.limbs.len - 1)
  if value.limbs.len == 1 and value.limbs[0] == 0:
    value.negative = false

proc makeNumber(value: int64): BigNumber =
  result.negative = value < 0
  var magnitude = value
  if magnitude < 0:
    magnitude = -magnitude
  result.limbs = @[]
  if magnitude == 0:
    result.limbs.add 0
  else:
    while magnitude > 0:
      result.limbs.add(magnitude mod limbBase)
      magnitude = magnitude div limbBase
  normalizeNumber(result)

proc magnitudeCompare(left, right: BigNumber): int =
  if left.limbs.len != right.limbs.len:
    if left.limbs.len > right.limbs.len:
      return 1
    return -1
  var position = left.limbs.len - 1
  while position >= 0:
    if left.limbs[position] != right.limbs[position]:
      if left.limbs[position] > right.limbs[position]:
        return 1
      return -1
    position -= 1
  return 0

proc subtractMagnitude(left, right: BigNumber): BigNumber =
  result.negative = false
  result.limbs = newSeq[int64](left.limbs.len)
  var borrow: int64 = 0
  for position in 0 .. left.limbs.len - 1:
    var difference = left.limbs[position] - borrow
    if position < right.limbs.len:
      difference = difference - right.limbs[position]
    if difference < 0:
      difference = difference + limbBase
      borrow = 1
    else:
      borrow = 0
    result.limbs[position] = difference
  normalizeNumber(result)

proc addNumbers(left, right: BigNumber): BigNumber =
  if left.negative == right.negative:
    result.negative = left.negative
    result.limbs = newSeq[int64](max(left.limbs.len, right.limbs.len) + 1)
    var carry: int64 = 0
    for position in 0 .. result.limbs.len - 2:
      var total: int64 = carry
      if position < left.limbs.len:
        total = total + left.limbs[position]
      if position < right.limbs.len:
        total = total + right.limbs[position]
      result.limbs[position] = total mod limbBase
      carry = total div limbBase
    result.limbs[result.limbs.len - 1] = carry
    normalizeNumber(result)
  else:
    let order = magnitudeCompare(left, right)
    if order >= 0:
      result = subtractMagnitude(left, right)
      result.negative = left.negative and order != 0
    else:
      result = subtractMagnitude(right, left)
      result.negative = right.negative
    normalizeNumber(result)

proc scaleNumber(value: BigNumber, factor: int64): BigNumber =
  result.negative = value.negative != (factor < 0)
  var multiplier = factor
  if multiplier < 0:
    multiplier = -multiplier
  result.limbs = newSeq[int64](value.limbs.len + 1)
  var carry: int64 = 0
  for position in 0 .. value.limbs.len - 1:
    let product = value.limbs[position] * multiplier + carry
    result.limbs[position] = product mod limbBase
    carry = product div limbBase
  result.limbs[value.limbs.len] = carry
  normalizeNumber(result)

proc numberToText(value: BigNumber): string =
  if value.negative:
    result.add '-'
  let highest = value.limbs.len - 1
  result.add $value.limbs[highest]
  var position = highest - 1
  while position >= 0:
    let part = $value.limbs[position]
    var zeroCount = 9 - part.len
    while zeroCount > 0:
      result.add '0'
      zeroCount -= 1
    result.add part
    position -= 1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var stirlingValues = newSeq[seq[int64]](maxDegree + 1)
for outerIndex in 0 .. maxDegree:
  stirlingValues[outerIndex] = newSeq[int64](maxDegree + 1)
stirlingValues[0][0] = 1
for degreeIndex in 1 .. maxDegree:
  for subsetIndex in 1 .. degreeIndex:
    stirlingValues[degreeIndex][subsetIndex] =
      stirlingValues[degreeIndex - 1][subsetIndex - 1] +
      int64(subsetIndex) * stirlingValues[degreeIndex - 1][subsetIndex]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let degree = nextInt(inputData, scanPos)
  let differenceOrder = nextInt(inputData, scanPos)
  var coefficients = newSeq[int64](degree + 1)
  for placeIndex in 0 .. degree:
    coefficients[degree - placeIndex] = int64(nextInt(inputData, scanPos))
  var total = makeNumber(0)
  for exponent in differenceOrder .. degree:
    var term = makeNumber(stirlingValues[exponent][differenceOrder])
    for multiplier in 1 .. differenceOrder:
      term = scaleNumber(term, int64(multiplier))
    let coefficient = coefficients[exponent]
    if coefficient != 0:
      term = scaleNumber(term, coefficient)
      total = addNumbers(total, term)
  appendOutput(numberToText(total))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
