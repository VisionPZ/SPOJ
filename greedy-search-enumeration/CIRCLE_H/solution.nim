const flushBlockBytes = 1 shl 17
const limbBase = 1000000000
const precisionDigits = 60
const fractionDigits = 50

type LargeNumber = seq[int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

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

proc normalizeNumber(value: var LargeNumber) =
  while value.len > 0 and value[value.len - 1] == 0:
    value.setLen value.len - 1

proc fromDigits(text: string, startPos: int, digitCount: int): LargeNumber =
  result = newSeq[int](0)
  var endPos = startPos + digitCount
  while endPos > startPos:
    var groupStart = endPos - 9
    if groupStart < startPos:
      groupStart = startPos
    var limb = 0
    for digitPos in groupStart .. endPos - 1:
      limb = limb * 10 + int(text[digitPos]) - 48
    result.add limb
    endPos = groupStart
  normalizeNumber(result)

proc decimalDigits(value: int): int =
  result = 1
  var remaining = value
  while remaining >= 10:
    remaining = remaining div 10
    result += 1

proc addNumbers(left: LargeNumber, right: LargeNumber): LargeNumber =
  result = newSeq[int](max(left.len, right.len))
  var carry = 0
  for index in 0 .. result.len - 1:
    var total = carry
    if index < left.len:
      total = total + left[index]
    if index < right.len:
      total = total + right[index]
    result[index] = total mod limbBase
    carry = total div limbBase
  if carry > 0:
    result.add carry
  normalizeNumber(result)

proc multiplySmall(value: LargeNumber, factor: int64): LargeNumber =
  if value.len == 0 or factor == 0:
    return newSeq[int](0)
  result = newSeq[int](value.len)
  var carry: int64 = 0
  for index in 0 .. value.len - 1:
    let product = int64(value[index]) * factor + carry
    result[index] = int(product mod int64(limbBase))
    carry = product div int64(limbBase)
  while carry > 0:
    result.add int(carry mod int64(limbBase))
    carry = carry div int64(limbBase)
  normalizeNumber(result)

proc multiplyNumbers(left: LargeNumber, right: LargeNumber): LargeNumber =
  if left.len == 0 or right.len == 0:
    return newSeq[int](0)
  result = newSeq[int](left.len + right.len)
  for leftIndex in 0 .. left.len - 1:
    var carry: int64 = 0
    for rightIndex in 0 .. right.len - 1:
      let position = leftIndex + rightIndex
      let product = int64(result[position]) + int64(left[leftIndex]) * int64(right[rightIndex]) + carry
      result[position] = int(product mod int64(limbBase))
      carry = product div int64(limbBase)
    var position = leftIndex + right.len
    while carry > 0:
      let product = int64(result[position]) + carry
      result[position] = int(product mod int64(limbBase))
      carry = product div int64(limbBase)
      position += 1
  normalizeNumber(result)

proc compareNumbers(left: LargeNumber, right: LargeNumber): int =
  if left.len != right.len:
    if left.len < right.len:
      return -1
    return 1
  var index = left.len - 1
  while index >= 0:
    if left[index] != right[index]:
      if left[index] < right[index]:
        return -1
      return 1
    index -= 1
  return 0

proc subtractNumbers(left: LargeNumber, right: LargeNumber): LargeNumber =
  result = newSeq[int](left.len)
  var borrow = 0
  var index = 0
  while index < left.len:
    var difference = left[index] - borrow
    if index < right.len:
      difference = difference - right[index]
    if difference < 0:
      difference = difference + limbBase
      borrow = 1
    else:
      borrow = 0
    result[index] = difference
    index += 1
  normalizeNumber(result)

proc shiftDecimal(value: LargeNumber, digits: int): LargeNumber =
  if value.len == 0:
    return newSeq[int](0)
  let wholeLimbs = digits div 9
  let extraDigits = digits mod 9
  result = newSeq[int](value.len + wholeLimbs)
  for index in 0 .. value.len - 1:
    result[index + wholeLimbs] = value[index]
  if extraDigits > 0:
    var multiplier = 1
    for _ in 1 .. extraDigits:
      multiplier = multiplier * 10
    return multiplySmall(result, int64(multiplier))
  return result

proc divideNumbers(dividend: LargeNumber, divisor: LargeNumber): tuple[quotient: LargeNumber, remainder: LargeNumber] =
  if compareNumbers(dividend, divisor) < 0:
    return (newSeq[int](0), dividend)
  var quotient = newSeq[int](dividend.len)
  var remainder = newSeq[int](0)
  var index = dividend.len - 1
  while index >= 0:
    remainder = multiplySmall(remainder, int64(limbBase))
    if dividend[index] > 0:
      remainder = addNumbers(remainder, @[dividend[index]])
    var low = 0
    var high = limbBase - 1
    while low < high:
      let middle = (low + high + 1) div 2
      if compareNumbers(multiplySmall(divisor, int64(middle)), remainder) <= 0:
        low = middle
      else:
        high = middle - 1
    quotient[index] = low
    if low > 0:
      remainder = subtractNumbers(remainder, multiplySmall(divisor, int64(low)))
    index -= 1
  normalizeNumber(quotient)
  return (quotient, remainder)

proc halfNumber(value: LargeNumber): LargeNumber =
  result = newSeq[int](value.len)
  var carry = 0
  var index = value.len - 1
  while index >= 0:
    let current = value[index] + carry * limbBase
    result[index] = current div 2
    carry = current mod 2
    index -= 1
  normalizeNumber(result)

proc isqrtNumber(value: LargeNumber): LargeNumber =
  if value.len == 0:
    return newSeq[int](0)
  let digitCount = (value.len - 1) * 9 + decimalDigits(value[value.len - 1])
  var guess = shiftDecimal(@[1], (digitCount + 1) div 2)
  while true:
    let division = divideNumbers(value, guess)
    let nextGuess = halfNumber(addNumbers(guess, division.quotient))
    if compareNumbers(nextGuess, guess) >= 0:
      return guess
    guess = nextGuess

proc numberToString(value: LargeNumber): string =
  if value.len == 0:
    return "0"
  result = $value[value.len - 1]
  var index = value.len - 2
  while index >= 0:
    let limbText = $value[index]
    for _ in 1 .. 9 - limbText.len:
      result.add '0'
    result.add limbText
    index -= 1

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let radiusOneToken = nextToken(inputData, scanPos)
  let radiusTwoToken = nextToken(inputData, scanPos)
  let radiusThreeToken = nextToken(inputData, scanPos)
  let radiusOne = fromDigits(radiusOneToken, 0, radiusOneToken.len)
  let radiusTwo = fromDigits(radiusTwoToken, 0, radiusTwoToken.len)
  let radiusThree = fromDigits(radiusThreeToken, 0, radiusThreeToken.len)
  let productRadii = multiplyNumbers(multiplyNumbers(radiusOne, radiusTwo), radiusThree)
  let sumPairwise = addNumbers(addNumbers(multiplyNumbers(radiusOne, radiusTwo), multiplyNumbers(radiusTwo, radiusThree)), multiplyNumbers(radiusThree, radiusOne))
  let sumRadii = addNumbers(addNumbers(radiusOne, radiusTwo), radiusThree)
  let rootInput = shiftDecimal(multiplyNumbers(productRadii, sumRadii), 2 * precisionDigits)
  let scaledRoot = isqrtNumber(rootInput)
  let denominator = addNumbers(shiftDecimal(sumPairwise, precisionDigits), multiplySmall(scaledRoot, 2))
  let numerator = shiftDecimal(productRadii, fractionDigits + precisionDigits)
  let scaledRadius = divideNumbers(numerator, denominator).quotient
  let digitText = numberToString(scaledRadius)
  var integerPart = "0"
  var fractionPart = ""
  if digitText.len > fractionDigits:
    integerPart = digitText[0 .. digitText.len - fractionDigits - 1]
    fractionPart = digitText[digitText.len - fractionDigits .. digitText.len - 1]
  else:
    for _ in 1 .. fractionDigits - digitText.len:
      fractionPart.add '0'
    fractionPart.add digitText
  appendOutput(integerPart)
  appendOutput(".")
  appendOutput(fractionPart)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
