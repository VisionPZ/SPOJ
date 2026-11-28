import math

const limbBase = 1000000000
const fractionalDigits = 380
const outputDigits = 101
const flushBlockBytes = 1 shl 17

type BigNumber = seq[int32]

proc trimBig(value: var BigNumber) =
  while value.len > 0 and value[value.len - 1] == 0:
    value.setLen(value.len - 1)

proc multiplySmall(value: var BigNumber, factor: int32) =
  if factor == 0:
    value.setLen 0
    return
  var carry: int64 = 0
  for index in 0 .. value.len - 1:
    let combined = int64(value[index]) * int64(factor) + carry
    value[index] = int32(combined mod int64(limbBase))
    carry = combined div int64(limbBase)
  while carry > 0:
    value.add int32(carry mod int64(limbBase))
    carry = carry div int64(limbBase)

proc scaledSmall(value: BigNumber, factor: int32): BigNumber =
  var copy = value
  multiplySmall(copy, factor)
  return copy

proc addSmall(value: var BigNumber, digit: int32) =
  var carry: int64 = int64(digit)
  var position = 0
  while carry > 0 and position < value.len:
    let combined = int64(value[position]) + carry
    value[position] = int32(combined mod int64(limbBase))
    carry = combined div int64(limbBase)
    position = position + 1
  while carry > 0:
    value.add int32(carry mod int64(limbBase))
    carry = carry div int64(limbBase)

proc compareBig(left: BigNumber, right: BigNumber): int =
  if left.len > right.len: return 1
  if left.len < right.len: return -1
  for index in countdown(left.len - 1, 0):
    if left[index] > right[index]: return 1
    if left[index] < right[index]: return -1
  return 0

proc addBig(left: BigNumber, right: BigNumber): BigNumber =
  var answer: BigNumber = @[]
  let longest = max(left.len, right.len)
  answer.setLen longest
  var carry: int64 = 0
  for index in 0 .. longest - 1:
    var combined = carry
    if index < left.len: combined = combined + int64(left[index])
    if index < right.len: combined = combined + int64(right[index])
    answer[index] = int32(combined mod int64(limbBase))
    carry = combined div int64(limbBase)
  if carry > 0: answer.add int32(carry)
  trimBig(answer)
  return answer

proc subtractBig(left: BigNumber, right: BigNumber): BigNumber =
  var answer: BigNumber = @[]
  answer.setLen left.len
  var borrow: int64 = 0
  for index in 0 .. left.len - 1:
    var difference = int64(left[index]) - borrow
    if index < right.len: difference = difference - int64(right[index])
    if difference < 0:
      difference = difference + int64(limbBase)
      borrow = 1
    else:
      borrow = 0
    answer[index] = int32(difference)
  trimBig(answer)
  return answer

proc multiplyBig(left: BigNumber, right: BigNumber): BigNumber =
  if left.len == 0 or right.len == 0:
    return @[]
  var answer = newSeq[int32](left.len + right.len)
  for leftIndex in 0 .. left.len - 1:
    var carry: int64 = 0
    for rightIndex in 0 .. right.len - 1:
      let slot = leftIndex + rightIndex
      let combined = int64(answer[slot]) + int64(left[leftIndex]) * int64(right[rightIndex]) + carry
      answer[slot] = int32(combined mod int64(limbBase))
      carry = combined div int64(limbBase)
    var slot = leftIndex + right.len
    while carry > 0:
      let combined = int64(answer[slot]) + carry
      answer[slot] = int32(combined mod int64(limbBase))
      carry = combined div int64(limbBase)
      slot = slot + 1
  trimBig(answer)
  return answer

proc divideSmallInPlace(value: var BigNumber, divisor: int32): int32 =
  var remainder: int64 = 0
  for index in countdown(value.len - 1, 0):
    let combined = remainder * int64(limbBase) + int64(value[index])
    value[index] = int32(combined div int64(divisor))
    remainder = combined mod int64(divisor)
  trimBig(value)
  return int32(remainder)

proc divideSmall(value: BigNumber, divisor: int32): BigNumber =
  var copy = value
  discard divideSmallInPlace(copy, divisor)
  return copy

proc powerOfTen(digitCount: int): BigNumber =
  var value: BigNumber = @[int32(1)]
  for _ in 1 .. digitCount:
    multiplySmall(value, 10)
  return value

proc multiplyByPowerOfTen(value: BigNumber, digitCount: int): BigNumber =
  if value.len == 0: return @[]
  let limbShift = digitCount div 9
  let digitRemainder = digitCount mod 9
  var answer = newSeq[int32](value.len + limbShift + 1)
  for index in 0 .. value.len - 1:
    answer[index + limbShift] = value[index]
  if digitRemainder > 0:
    multiplySmall(answer, int32(pow(10.0, float(digitRemainder))))
  trimBig(answer)
  return answer

proc divideByPowerOfTen(value: BigNumber, digitCount: int): BigNumber =
  let limbShift = digitCount div 9
  if limbShift >= value.len: return @[]
  var answer = newSeq[int32](value.len - limbShift)
  for index in limbShift .. value.len - 1:
    answer[index - limbShift] = value[index]
  let digitRemainder = digitCount mod 9
  if digitRemainder > 0:
    discard divideSmallInPlace(answer, int32(pow(10.0, float(digitRemainder))))
  trimBig(answer)
  return answer

proc decimalLength(value: BigNumber): int =
  if value.len == 0: return 1
  var topValue = int64(value[value.len - 1])
  var digits = 0
  while topValue > 0:
    digits = digits + 1
    topValue = topValue div 10
  return 9 * (value.len - 1) + digits

proc toDecimal(value: BigNumber): string =
  if value.len == 0: return "0"
  var rendered = ""
  rendered.add $int64(value[value.len - 1])
  for index in countdown(value.len - 2, 0):
    var limbValue = int64(value[index])
    var group = ""
    for place in 0 .. 8:
      group = char(48 + limbValue mod 10) & group
      limbValue = limbValue div 10
    rendered.add group
  return rendered

proc parseFixed(text: string): BigNumber =
  var wholeDigits = ""
  var fractionDigits = ""
  var afterPoint = false
  for character in text:
    if character == '.':
      afterPoint = true
    elif character >= '0' and character <= '9':
      if afterPoint:
        fractionDigits.add character
      else:
        wholeDigits.add character
  var value: BigNumber = @[]
  for character in wholeDigits:
    multiplySmall(value, 10)
    addSmall(value, int32(ord(character) - 48))
  value = multiplyByPowerOfTen(value, fractionalDigits)
  if fractionDigits.len > 0:
    let kept = min(fractionalDigits, fractionDigits.len)
    var fractionValue: BigNumber = @[]
    for index in 0 .. kept - 1:
      multiplySmall(fractionValue, 10)
      addSmall(fractionValue, int32(ord(fractionDigits[index]) - 48))
    value = addBig(value, multiplyByPowerOfTen(fractionValue, fractionalDigits - kept))
  return value

proc multiplyFixed(left: BigNumber, right: BigNumber): BigNumber =
  return divideByPowerOfTen(multiplyBig(left, right), fractionalDigits)

proc reciprocalFixed(value: BigNumber): BigNumber =
  if value.len == 0: return @[]
  let unitValue = powerOfTen(fractionalDigits)
  let decimalExponent = decimalLength(value) - 1 - fractionalDigits
  var guess = powerOfTen(fractionalDigits - decimalExponent)
  discard divideSmallInPlace(guess, 8)
  let doubleUnit = scaledSmall(unitValue, 2)
  for iteration in 1 .. 18:
    let product = multiplyFixed(value, guess)
    if compareBig(product, doubleUnit) >= 0: break
    let complement = subtractBig(doubleUnit, product)
    guess = multiplyFixed(guess, complement)
  return guess

proc divideFixed(numerator: BigNumber, denominator: BigNumber): BigNumber =
  if numerator.len == 0 or denominator.len == 0: return @[]
  return multiplyFixed(numerator, reciprocalFixed(denominator))

proc formatSignificant(value: BigNumber): string =
  if value.len == 0: return "0"
  let shift = decimalLength(value) - outputDigits
  var digits: BigNumber = @[]
  if shift <= 0:
    digits = multiplyByPowerOfTen(value, -shift)
  else:
    digits = divideByPowerOfTen(value, shift)
  var rendered = toDecimal(digits)
  while rendered.len > 1 and rendered[rendered.len - 1] == '0':
    rendered.setLen(rendered.len - 1)
  return rendered

proc nextIndex(inputData: string, position: var int): int =
  while position < inputData.len and (inputData[position] < '0' or inputData[position] > '9'):
    position = position + 1
  var value = 0
  while position < inputData.len and inputData[position] >= '0' and inputData[position] <= '9':
    value = value * 10 + ord(inputData[position]) - 48
    position = position + 1
  return value

proc nextToken(inputData: string, position: var int): string =
  while position < inputData.len and inputData[position] <= ' ':
    position = position + 1
  var token = ""
  while position < inputData.len and inputData[position] > ' ':
    token.add inputData[position]
    position = position + 1
  return token

proc atanhSeries(argument: BigNumber): BigNumber =
  let squared = multiplyFixed(argument, argument)
  var power = argument
  var total = argument
  var denominator = 1
  while denominator <= 900:
    power = multiplyFixed(power, squared)
    denominator = denominator + 2
    let term = divideSmall(power, int32(denominator))
    if term.len == 0: break
    total = addBig(total, term)
  return scaledSmall(total, 2)

proc logarithmFixed(value: BigNumber, logarithmOfTwo: BigNumber): BigNumber =
  let unitValue = powerOfTen(fractionalDigits)
  let twoValue = scaledSmall(unitValue, 2)
  var mantissa = value
  var twosRemoved = 0
  while compareBig(mantissa, twoValue) >= 0:
    mantissa = divideSmall(mantissa, 2)
    twosRemoved = twosRemoved + 1
  let numerator = subtractBig(mantissa, unitValue)
  let denominator = addBig(mantissa, unitValue)
  let argument = divideFixed(numerator, denominator)
  var answer = atanhSeries(argument)
  if twosRemoved > 0:
    answer = addBig(answer, scaledSmall(logarithmOfTwo, int32(twosRemoved)))
  return answer

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var position = 0
let caseCount = nextIndex(inputData, position)
let unitValue = powerOfTen(fractionalDigits)
let thirdValue = divideSmall(unitValue, 3)
let logarithmOfTwo = atanhSeries(thirdValue)
var outputBuffer = ""
for caseIndex in 1 .. caseCount:
  let argumentToken = nextToken(inputData, position)
  let argumentValue = parseFixed(argumentToken)
  let answer = logarithmFixed(argumentValue, logarithmOfTwo)
  outputBuffer.add formatSignificant(answer)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
