import math

const flushBlockBytes = 1 shl 17
const sweepLimit = 2000000
const trialLimit = 2000000
const bigBase = 1000000000'i64

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

type BigNum = seq[int64]

proc normalizeBig(value: var BigNum) =
  while value.len > 0 and value[value.len - 1] == 0:
    value.setLen(value.len - 1)

proc fromSmall(value: int64): BigNum =
  result = newSeq[int64]()
  if value >= bigBase:
    result.add value mod bigBase
    result.add value div bigBase
  elif value > 0:
    result.add value
  normalizeBig(result)

proc addBig(left, right: BigNum): BigNum =
  var result = newSeq[int64](left.len + right.len)
  var index: int = 0
  var carry: int64 = 0
  while index < left.len or index < right.len:
    var total = carry
    if index < left.len:
      total += left[index]
    if index < right.len:
      total += right[index]
    result[index] = total mod bigBase
    carry = total div bigBase
    index += 1
  if carry > 0:
    if index < result.len:
      result[index] = carry
    else:
      result.add carry
  normalizeBig(result)
  return result

proc subBig(left, right: BigNum): BigNum =
  var result = newSeq[int64](left.len)
  var index: int = 0
  var borrow: int64 = 0
  while index < left.len:
    var difference = left[index] - borrow
    if index < right.len:
      difference -= right[index]
    if difference < 0:
      difference += bigBase
      borrow = 1
    else:
      borrow = 0
    result[index] = difference
    index += 1
  normalizeBig(result)
  return result

proc mulBig(left, right: BigNum): BigNum =
  if left.len == 0 or right.len == 0:
    return @[]
  var result = newSeq[int64](left.len + right.len)
  for leftIndex in 0 .. left.len - 1:
    var carry: int64 = 0
    for rightIndex in 0 .. right.len - 1:
      let position = leftIndex + rightIndex
      let product = left[leftIndex] * right[rightIndex] + result[position] + carry
      result[position] = product mod bigBase
      carry = product div bigBase
    var position = leftIndex + right.len
    while carry > 0:
      let accumulated = result[position] + carry
      result[position] = accumulated mod bigBase
      carry = accumulated div bigBase
      position += 1
  normalizeBig(result)
  return result

proc compareBig(left, right: BigNum): int =
  if left.len != right.len:
    if left.len > right.len:
      return 1
    return -1
  var index = left.len - 1
  while index >= 0:
    if left[index] != right[index]:
      if left[index] > right[index]:
        return 1
      return -1
    index -= 1
  return 0

proc toStringBig(value: BigNum): string =
  if value.len == 0:
    return "0"
  result = $value[value.len - 1]
  var index = value.len - 2
  while index >= 0:
    let limb = value[index]
    result.add chr(48 + int(limb div 100000000))
    result.add chr(48 + int((limb div 10000000) mod 10))
    result.add chr(48 + int((limb div 1000000) mod 10))
    result.add chr(48 + int((limb div 100000) mod 10))
    result.add chr(48 + int((limb div 10000) mod 10))
    result.add chr(48 + int((limb div 1000) mod 10))
    result.add chr(48 + int((limb div 100) mod 10))
    result.add chr(48 + int((limb div 10) mod 10))
    result.add chr(48 + int(limb mod 10))
    index -= 1

proc triangularBig(value: int64): BigNum =
  if (value and 1'i64) == 0:
    return mulBig(fromSmall(value div 2), fromSmall(value + 1))
  return mulBig(fromSmall(value), fromSmall((value + 1) div 2))

proc integerSquareRoot(value: int64): int64 =
  var candidate = int64(sqrt(float64(value)))
  while (candidate + 1) * (candidate + 1) <= value:
    candidate += 1
  while candidate * candidate > value:
    candidate -= 1
  return candidate

proc considerShape(width, height: int64, availableMatches: int64, bestValue: var BigNum) =
  if width < 1 or height < 1:
    return
  let span = 2 * width * height + width - height
  if span > availableMatches:
    return
  var fullRows = (availableMatches - span) div 2
  if fullRows > height:
    fullRows = height
  if fullRows < 1:
    return
  if fullRows < height and width < 2:
    return
  let widthTriangles = triangularBig(width)
  let heightTriangles = triangularBig(height)
  let fullTriangles = triangularBig(fullRows)
  var candidate = mulBig(widthTriangles, fullTriangles)
  if fullRows < height:
    let remainder = subBig(heightTriangles, fullTriangles)
    candidate = addBig(candidate, mulBig(triangularBig(width - 1), remainder))
  if compareBig(candidate, bestValue) > 0:
    bestValue = candidate

proc sweepShapes(matchCount: int64, bestValue: var BigNum) =
  let sweepHeight = min(integerSquareRoot(matchCount div 2) + 2, int64(sweepLimit))
  var height: int64 = 1
  while height <= sweepHeight:
    let span = 2 * height + 1
    let approximateWidth = (matchCount + height) div span
    var offset = -2
    while offset <= 1:
      considerShape(approximateWidth + offset, height, matchCount, bestValue)
      offset += 1
    height += 1

proc factorValue(value: int64): seq[int64] =
  var factors = newSeq[int64]()
  var remainder = value
  var candidate: int64 = 2
  while candidate <= trialLimit and candidate * candidate <= remainder:
    if remainder mod candidate == 0:
      factors.add candidate
      while remainder mod candidate == 0:
        remainder = remainder div candidate
    if candidate == 2:
      candidate = 3
    else:
      candidate += 2
  if remainder > 1:
    factors.add remainder
  return factors

proc divisorCandidates(matchCount: int64, bestValue: var BigNum) =
  let product = 2 * matchCount + 1
  let factors = factorValue(product)
  var divisors = newSeq[int64]()
  divisors.add 1
  for factor in factors:
    var exponent: int = 0
    var probe = product
    while probe mod factor == 0:
      probe = probe div factor
      exponent += 1
    let currentCount = divisors.len
    var multiplier: int64 = 1
    for powerIndex in 1 .. exponent:
      multiplier *= factor
      for index in 0 .. currentCount - 1:
        divisors.add divisors[index] * multiplier
  for divisor in divisors:
    if divisor > product:
      continue
    if product mod divisor != 0:
      continue
    let other = product div divisor
    if divisor > other:
      continue
    let height = (divisor - 1) div 2
    let width = (other - 1) div 2
    considerShape(width, height, matchCount, bestValue)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let matchCount = int64(nextInt(inputData, scanPos))
  var bestValue = fromSmall(0)
  sweepShapes(matchCount, bestValue)
  divisorCandidates(matchCount, bestValue)
  appendOutput(toStringBig(bestValue))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
