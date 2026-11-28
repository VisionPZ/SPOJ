const limbBase = 1000000000
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

proc parseBig(text: string): BigNumber =
  var value: BigNumber = @[]
  for character in text:
    if character >= '0' and character <= '9':
      multiplySmall(value, 10)
      addSmall(value, int32(ord(character) - 48))
  trimBig(value)
  return value

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

proc divideModulo(dividend: BigNumber, divisor: BigNumber): tuple[quotient: BigNumber, remainder: BigNumber] =
  if divisor.len == 0:
    return (@[], @[])
  if compareBig(dividend, divisor) < 0:
    return (@[], dividend)
  var remainder: BigNumber = @[]
  var quotient = newSeq[int32](dividend.len)
  for index in countdown(dividend.len - 1, 0):
    var shifted = newSeq[int32](remainder.len + 1)
    shifted[0] = dividend[index]
    for place in 0 .. remainder.len - 1:
      shifted[place + 1] = remainder[place]
    remainder = shifted
    trimBig(remainder)
    var low: int32 = 0
    var high: int32 = int32(limbBase - 1)
    while low < high:
      let middle = (low + high + 1) div 2
      let trial = scaledSmall(divisor, middle)
      if compareBig(trial, remainder) <= 0:
        low = middle
      else:
        high = middle - 1
    quotient[index] = low
    if low > 0:
      remainder = subtractBig(remainder, scaledSmall(divisor, low))
  trimBig(quotient)
  return (quotient, remainder)

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

proc baseHundredDigits(value: BigNumber): seq[int32] =
  var working = value
  var digits: seq[int32] = @[]
  while working.len > 0:
    digits.add divideSmallInPlace(working, 100)
  return digits

proc truncatedProduct(left: BigNumber, right: BigNumber, skip: int): string =
  let leftDigits = baseHundredDigits(left)
  let rightDigits = baseHundredDigits(right)
  if leftDigits.len == 0 or rightDigits.len == 0: return "0"
  var convolution = newSeq[int64](leftDigits.len + rightDigits.len - 1)
  for leftIndex in 0 .. leftDigits.len - 1:
    for rightIndex in 0 .. rightDigits.len - 1:
      convolution[leftIndex + rightIndex] = convolution[leftIndex + rightIndex] + int64(leftDigits[leftIndex]) * int64(rightDigits[rightIndex])
  var digitList: seq[int64] = @[]
  var carry: int64 = 0
  if skip < convolution.len:
    for index in skip .. convolution.len - 1:
      let combined = convolution[index] + carry
      carry = combined div 100
      digitList.add combined mod 100
  while carry > 0:
    digitList.add carry mod 100
    carry = carry div 100
  if digitList.len == 0: return "0"
  var rendered = $digitList[digitList.len - 1]
  for index in countdown(digitList.len - 2, 0):
    if digitList[index] < 10: rendered.add '0'
    rendered.add $digitList[index]
  return rendered

proc nextToken(inputData: string, position: var int): string =
  while position < inputData.len and inputData[position] <= ' ':
    position = position + 1
  var token = ""
  while position < inputData.len and inputData[position] > ' ':
    token.add inputData[position]
    position = position + 1
  return token

proc nextIndex(inputData: string, position: var int): int =
  while position < inputData.len and (inputData[position] < '0' or inputData[position] > '9'):
    position = position + 1
  var value = 0
  while position < inputData.len and inputData[position] >= '0' and inputData[position] <= '9':
    value = value * 10 + ord(inputData[position]) - 48
    position = position + 1
  return value

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var position = 0
let caseCount = nextIndex(inputData, position)
var outputBuffer = ""

for caseIndex in 1 .. caseCount:
  let operation = nextToken(inputData, position)
  let leftText = nextToken(inputData, position)
  let rightText = nextToken(inputData, position)
  let leftOperand = parseBig(leftText)
  let rightOperand = parseBig(rightText)
  case operation[0]
  of '<':
    let relation = compareBig(leftOperand, rightOperand)
    if relation < 0:
      outputBuffer.add "1\n"
    elif relation > 0:
      outputBuffer.add "-1\n"
    else:
      outputBuffer.add "0\n"
  of '+':
    outputBuffer.add toDecimal(addBig(leftOperand, rightOperand))
    outputBuffer.add "\n"
  of '-':
    if compareBig(leftOperand, rightOperand) < 0:
      outputBuffer.add "0\n"
    else:
      outputBuffer.add toDecimal(subtractBig(leftOperand, rightOperand))
      outputBuffer.add "\n"
  of '*':
    outputBuffer.add toDecimal(multiplyBig(leftOperand, rightOperand))
    outputBuffer.add "\n"
  of '/':
    let parts = divideModulo(leftOperand, rightOperand)
    outputBuffer.add toDecimal(parts.quotient)
    outputBuffer.add " "
    outputBuffer.add toDecimal(parts.remainder)
    outputBuffer.add "\n"
  of '#':
    let skipCount = nextIndex(inputData, position)
    outputBuffer.add truncatedProduct(leftOperand, rightOperand, skipCount)
    outputBuffer.add "\n"
  else:
    discard
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
