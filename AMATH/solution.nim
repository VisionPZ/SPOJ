const flushBlockBytes = 1 shl 17
const limbBase = 1000000000

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var token = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc normalize(value: seq[int]): seq[int] =
  var trimmed = value
  while trimmed.len > 1 and trimmed[trimmed.len - 1] == 0:
    trimmed.setLen trimmed.len - 1
  return trimmed

proc fromDigits(text: string): seq[int] =
  var limbs = @[0]
  for ch in text:
    var carry = int(ch) - 48
    for limbIndex in 0 .. limbs.len - 1:
      let combined = limbs[limbIndex] * 10 + carry
      limbs[limbIndex] = combined mod limbBase
      carry = combined div limbBase
    if carry > 0:
      limbs.add carry
  return normalize(limbs)

proc paddedLimb(value: int): string =
  var text = $value
  while text.len < 9:
    text = "0" & text
  return text

proc toDigits(value: seq[int]): string =
  var text = $value[value.len - 1]
  var limbIndex = value.len - 2
  while limbIndex >= 0:
    text = text & paddedLimb(value[limbIndex])
    limbIndex -= 1
  return text

proc compareValues(left: seq[int], right: seq[int]): int =
  if left.len != right.len:
    if left.len < right.len:
      return -1
    return 1
  var limbIndex = left.len - 1
  while limbIndex >= 0:
    if left[limbIndex] != right[limbIndex]:
      if left[limbIndex] < right[limbIndex]:
        return -1
      return 1
    limbIndex -= 1
  return 0

proc divideSmall(value: seq[int], divisor: int): (seq[int], int) =
  var quotient = newSeq[int](value.len)
  var remainder = 0
  var limbIndex = value.len - 1
  while limbIndex >= 0:
    let combined = remainder * limbBase + value[limbIndex]
    quotient[limbIndex] = combined div divisor
    remainder = combined mod divisor
    limbIndex -= 1
  return (normalize(quotient), remainder)

proc multiplySmall(value: seq[int], factor: int): seq[int] =
  var product = newSeq[int](value.len + 1)
  var carry = 0
  for limbIndex in 0 .. value.len - 1:
    let combined = value[limbIndex] * factor + carry
    product[limbIndex] = combined mod limbBase
    carry = combined div limbBase
  product[value.len] = carry
  return normalize(product)

proc subtractValues(left: seq[int], right: seq[int]): seq[int] =
  var difference = newSeq[int](left.len)
  var borrow = 0
  for limbIndex in 0 .. left.len - 1:
    var leftLimb = left[limbIndex] - borrow
    let rightLimb = if limbIndex < right.len: right[limbIndex] else: 0
    if leftLimb < rightLimb:
      leftLimb = leftLimb + limbBase
      borrow = 1
    else:
      borrow = 0
    difference[limbIndex] = leftLimb - rightLimb
  return normalize(difference)

proc multiplyValues(left: seq[int], right: seq[int]): seq[int] =
  var product = newSeq[int](left.len + right.len)
  for leftIndex in 0 .. left.len - 1:
    var carry = 0
    for rightIndex in 0 .. right.len - 1:
      let combined = int64(left[leftIndex]) * int64(right[rightIndex]) +
                     int64(product[leftIndex + rightIndex]) + int64(carry)
      product[leftIndex + rightIndex] = int(combined mod int64(limbBase))
      carry = int(combined div int64(limbBase))
    var position = leftIndex + right.len
    while carry > 0:
      let combined = int64(product[position]) + int64(carry)
      product[position] = int(combined mod int64(limbBase))
      carry = int(combined div int64(limbBase))
      position += 1
  return normalize(product)

proc remainderOf(value: seq[int], modulus: seq[int]): seq[int] =
  var remainder = @[0]
  var limbIndex = value.len - 1
  while limbIndex >= 0:
    var shifted = newSeq[int](remainder.len + 1)
    shifted[0] = value[limbIndex]
    for inner in 0 .. remainder.len - 1:
      shifted[inner + 1] = remainder[inner]
    remainder = normalize(shifted)
    var low = 0
    var high = limbBase - 1
    while low < high:
      let middle = (low + high + 1) div 2
      if compareValues(multiplySmall(modulus, middle), remainder) <= 0:
        low = middle
      else:
        high = middle - 1
    if low > 0:
      remainder = subtractValues(remainder, multiplySmall(modulus, low))
    limbIndex -= 1
  return remainder

proc isOne(value: seq[int]): bool =
  return value.len == 1 and value[0] == 1

proc powerMod(baseValue: seq[int], exponent: seq[int], modulus: seq[int]): seq[int] =
  var powerResult = @[1]
  var factor = remainderOf(baseValue, modulus)
  var power = exponent
  while not (power.len == 1 and power[0] == 0):
    let divided = divideSmall(power, 2)
    power = divided[0]
    if divided[1] == 1:
      powerResult = remainderOf(multiplyValues(powerResult, factor), modulus)
    factor = remainderOf(multiplyValues(factor, factor), modulus)
  return powerResult

var primeFactors = @[2, 5]
while true:
  let numberText = nextToken(inputData, scanPos)
  if numberText.len == 0:
    break
  let powerK = nextInt(inputData, scanPos)
  let originalNumber = fromDigits(numberText)
  var twos = 0
  var reduced = originalNumber
  while true:
    let divided = divideSmall(reduced, 2)
    if divided[1] != 0:
      break
    twos += 1
    reduced = divided[0]
  var fives = 0
  reduced = originalNumber
  while true:
    let divided = divideSmall(reduced, 5)
    if divided[1] != 0:
      break
    fives += 1
    reduced = divided[0]
  if (twos > 0 and twos < powerK) or (fives > 0 and fives < powerK):
    appendOutput("-1")
    outputBuffer.add '\n'
    continue
  var modulusValue = @[1]
  var phiValue = @[1]
  if twos == 0:
    var powerTwo = @[1]
    var exponentTwo = powerK
    while exponentTwo > 0:
      powerTwo = multiplySmall(powerTwo, 2)
      exponentTwo -= 1
    modulusValue = multiplyValues(modulusValue, powerTwo)
    var phiTwo = @[1]
    var phiExponent = powerK - 1
    while phiExponent > 0:
      phiTwo = multiplySmall(phiTwo, 2)
      phiExponent -= 1
    phiValue = multiplyValues(phiValue, phiTwo)
  if fives == 0:
    var powerFive = @[1]
    var exponentFive = powerK
    while exponentFive > 0:
      powerFive = multiplySmall(powerFive, 5)
      exponentFive -= 1
    modulusValue = multiplyValues(modulusValue, powerFive)
    var phiFive = @[4]
    var phiExponent = powerK - 1
    while phiExponent > 0:
      phiFive = multiplySmall(phiFive, 5)
      phiExponent -= 1
    phiValue = multiplyValues(phiValue, phiFive)
  if isOne(modulusValue):
    appendOutput("1")
    outputBuffer.add '\n'
    continue
  var orderValue = phiValue
  for primeFactor in primeFactors:
    while true:
      let divided = divideSmall(orderValue, primeFactor)
      if divided[1] != 0:
        break
      if isOne(powerMod(originalNumber, divided[0], modulusValue)):
        orderValue = divided[0]
      else:
        break
  appendOutput(toDigits(orderValue))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
