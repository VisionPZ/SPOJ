const flushBlockBytes = 1 shl 17
const maxNumber = 10000

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

proc nextNumber(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  var firstDigit = startPos
  while firstDigit < pos - 1 and data[firstDigit] == '0':
    firstDigit += 1
  return data[firstDigit .. pos - 1]

proc multiplyDecimal(value: string, factor: int): string =
  var carry = 0
  var digits = newSeq[int](value.len)
  for index in 0 .. value.len - 1:
    let digitPos = value.len - 1 - index
    let product = (int(value[digitPos]) - 48) * factor + carry
    digits[index] = product mod 10
    carry = product div 10
  var carryDigits = ""
  while carry > 0:
    carryDigits.add char(48 + carry mod 10)
    carry = carry div 10
  var decimalResult = ""
  for index in 0 .. carryDigits.len - 1:
    decimalResult.add char(carryDigits[carryDigits.len - 1 - index])
  for index in 0 .. value.len - 1:
    decimalResult.add char(48 + digits[value.len - 1 - index])
  return decimalResult

proc divideDecimal(value: string, divisor: int): string =
  var remainder = 0
  var decimalResult = ""
  for digitChar in value:
    let current = remainder * 10 + int(digitChar) - 48
    decimalResult.add char(48 + current div divisor)
    remainder = current mod divisor
  var firstDigit = 0
  while firstDigit < decimalResult.len - 1 and decimalResult[firstDigit] == '0':
    firstDigit += 1
  return decimalResult[firstDigit .. decimalResult.len - 1]

proc compareDecimal(left: string, right: string): int =
  if left.len < right.len:
    return -1
  if left.len > right.len:
    return 1
  for index in 0 .. left.len - 1:
    if left[index] < right[index]:
      return -1
    if left[index] > right[index]:
      return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var smallestFactor = newSeq[int](maxNumber + 1)
for prime in 2 .. maxNumber:
  if smallestFactor[prime] == 0:
    var multiple = prime
    while multiple <= maxNumber:
      if smallestFactor[multiple] == 0:
        smallestFactor[multiple] = prime
      multiple += prime

var primeExponents = newSeq[int](maxNumber + 1)
var divisorCounts = newSeq[string](maxNumber + 1)
divisorCounts[0] = "1"
var currentProduct = "1"
for factorialIndex in 1 .. maxNumber:
  var remaining = factorialIndex
  while remaining > 1:
    let prime = smallestFactor[remaining]
    var added = 0
    while remaining mod prime == 0:
      added += 1
      remaining = remaining div prime
    let oldExponent = primeExponents[prime]
    let newExponent = oldExponent + added
    currentProduct = multiplyDecimal(currentProduct, newExponent + 1)
    if oldExponent > 0:
      currentProduct = divideDecimal(currentProduct, oldExponent + 1)
    primeExponents[prime] = newExponent
  divisorCounts[factorialIndex] = currentProduct

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let query = nextNumber(inputData, scanPos)
  var low = 1
  var high = maxNumber
  while low < high:
    let middle = (low + high) div 2
    if compareDecimal(divisorCounts[middle], query) < 0:
      low = middle + 1
    else:
      high = middle
  if compareDecimal(divisorCounts[low], query) == 0:
    appendOutput($(low))
  else:
    appendOutput("nai")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
