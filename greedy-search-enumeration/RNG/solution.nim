const flushBlockBytes = 1 shl 17
const bigBase: int64 = 1000000000
const decimalScale: int64 = 1000000000
const decimalPlaces = 9

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and not ((data[pos] >= '0' and data[pos] <= '9') or data[pos] == '-'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type BigNumber = array[0 .. 3, int64]

proc makeBig(value: int64): BigNumber =
  var built: BigNumber = [0.int64, 0.int64, 0.int64, 0.int64]
  built[0] = value
  return built

proc multiplySmall(value: var BigNumber, factor: int64) =
  var carry: int64 = 0
  for limbIndex in 0 .. 3:
    let product = value[limbIndex] * factor + carry
    value[limbIndex] = product mod bigBase
    carry = product div bigBase

proc addBig(target: var BigNumber, other: BigNumber) =
  var carry: int64 = 0
  for limbIndex in 0 .. 3:
    let total = target[limbIndex] + other[limbIndex] + carry
    target[limbIndex] = total mod bigBase
    carry = total div bigBase

proc subtractBig(target: var BigNumber, other: BigNumber) =
  var borrow: int64 = 0
  for limbIndex in 0 .. 3:
    var difference = target[limbIndex] - other[limbIndex] - borrow
    if difference < 0:
      difference += bigBase
      borrow = 1
    else:
      borrow = 0
    target[limbIndex] = difference

proc compareBig(first: BigNumber, second: BigNumber): int =
  for limbIndex in countdown(3, 0):
    if first[limbIndex] > second[limbIndex]:
      return 1
    if first[limbIndex] < second[limbIndex]:
      return -1
  return 0

proc scaledBig(value: BigNumber, factor: int64): BigNumber =
  var built = value
  multiplySmall(built, factor)
  return built

proc differenceBig(first: BigNumber, second: BigNumber): BigNumber =
  var built = first
  subtractBig(built, second)
  return built

proc divideBig(numerator: BigNumber, denominator: BigNumber): tuple[quotient: BigNumber, remainder: BigNumber] =
  var quotient = makeBig(0)
  var remainder = makeBig(0)
  for limbIndex in countdown(3, 0):
    for higher in countdown(3, 1):
      remainder[higher] = remainder[higher - 1]
    remainder[0] = numerator[limbIndex]
    var low: int64 = 0
    var high: int64 = bigBase - 1
    while low < high:
      let middle = (low + high + 1) div 2
      if compareBig(scaledBig(denominator, middle), remainder) <= 0:
        low = middle
      else:
        high = middle - 1
    quotient[limbIndex] = low
    remainder = differenceBig(remainder, scaledBig(denominator, low))
  return (quotient, remainder)

proc cdfNumerator(reach: int, widths: seq[int]): BigNumber =
  var positive = makeBig(0)
  var negative = makeBig(0)
  let factorCount = widths.len
  let subsetCount = 1 shl factorCount
  for subsetMask in 0 .. subsetCount - 1:
    var subsetTotal = 0
    for factorIndex in 0 .. factorCount - 1:
      if (subsetMask and (1 shl factorIndex)) != 0:
        subsetTotal += widths[factorIndex]
    let distance = reach - subsetTotal
    if distance < 0:
      continue
    var power = makeBig(int64(distance))
    for exponent in 1 .. factorCount - 1:
      multiplySmall(power, int64(distance))
    var bitCount = 0
    var bits = subsetMask
    while bits != 0:
      bitCount += bits and 1
      bits = bits shr 1
    if (bitCount and 1) == 0:
      addBig(positive, power)
    else:
      addBig(negative, power)
  subtractBig(positive, negative)
  return positive

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let factorCount = nextInt(inputData, scanPos)
  let lowerBound = nextInt(inputData, scanPos)
  let upperBound = nextInt(inputData, scanPos)
  var widths = newSeq[int](factorCount)
  var halfSpan = 0
  for factorIndex in 0 .. factorCount - 1:
    widths[factorIndex] = 2 * nextInt(inputData, scanPos)
    halfSpan += widths[factorIndex] div 2
  var denominator = makeBig(1)
  for divisor in 1 .. factorCount:
    multiplySmall(denominator, int64(divisor))
  for width in widths:
    multiplySmall(denominator, int64(width))
  var upperNumerator = cdfNumerator(upperBound + halfSpan, widths)
  let lowerNumerator = cdfNumerator(lowerBound + halfSpan, widths)
  subtractBig(upperNumerator, lowerNumerator)
  let scaledNumerator = scaledBig(upperNumerator, decimalScale)
  let division = divideBig(scaledNumerator, denominator)
  var quotient = division.quotient
  if compareBig(scaledBig(division.remainder, 2), denominator) >= 0:
    addBig(quotient, makeBig(1))
  let wholePart = quotient[1]
  let fractionPart = quotient[0]
  var fractionText = $fractionPart
  while fractionText.len < decimalPlaces:
    fractionText = "0" & fractionText
  appendOutput($wholePart & "." & fractionText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
