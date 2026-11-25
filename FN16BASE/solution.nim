const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] >= '0' and data[checkPos] <= '9':
      return true
    checkPos += 1
  return false

proc evalDecimalInBase(decimalValue: int64, base: int64): int64 =
  var remaining = decimalValue
  var place: int64 = 1
  result = 0
  while remaining > 0:
    let digit = remaining mod 10
    if digit > 0 and place > high(int64) div digit:
      return high(int64)
    let part = digit * place
    if result > high(int64) - part:
      return high(int64)
    result += part
    if remaining >= 10:
      if place > high(int64) div base:
        return high(int64)
      place *= base
    remaining = remaining div 10
  return result

proc worksInBase(age: int64, base: int64): bool =
  var remaining = age
  while remaining > 0:
    let digit = remaining mod base
    if digit >= 10:
      return false
    remaining = remaining div base
  return true

proc integerSquareRoot(value: int64): int64 =
  var low: int64 = 0
  var highValue: int64 = 1000000001
  while low < highValue - 1:
    let middle = (low + highValue) div 2
    if middle * middle > value:
      highValue = middle
    else:
      low = middle
  return low

proc baseForDecimalValue(age: int64, decimalValue: int64): int64 =
  let unitDigit = decimalValue mod 10
  if decimalValue < 100:
    let tensDigit = decimalValue div 10
    if tensDigit == 0:
      return -1
    if (age - unitDigit) mod tensDigit == 0:
      let candidate = (age - unitDigit) div tensDigit
      if candidate > tensDigit and candidate > unitDigit:
        return candidate
    return -1
  let tensDigit = (decimalValue div 10) mod 10
  let hundredsDigit = decimalValue div 100
  var low: int64 = 10
  var highValue = integerSquareRoot(age div hundredsDigit)
  while low < highValue - 1:
    let middle = (low + highValue) div 2
    let guess = hundredsDigit * middle * middle + tensDigit * middle + unitDigit
    if guess > age:
      highValue = middle - 1
    elif guess == age:
      return middle
    else:
      low = middle
  let lowGuess = hundredsDigit * low * low + tensDigit * low + unitDigit
  if lowGuess == age:
    return low
  let highGuess = hundredsDigit * (low + 1) * (low + 1) + tensDigit * (low + 1) + unitDigit
  if highGuess == age:
    return low + 1
  return -1

proc upperSearchBound(age: int64, lower: int64): int64 =
  var low: int64 = 10
  var highValue = age
  while low < highValue - 1:
    let middle = (low + highValue) div 2
    if evalDecimalInBase(lower, middle) > age:
      highValue = middle - 1
    else:
      low = middle
  if evalDecimalInBase(lower, low + 1) <= age:
    return low + 1
  return low

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasNextToken(inputData, scanPos):
  let age = nextInt64(inputData, scanPos)
  let lower = nextInt64(inputData, scanPos)
  let searchBound = upperSearchBound(age, lower)
  var bestBase: int64 = 10
  if searchBound < 1000000:
    var candidate = searchBound
    while candidate >= 2:
      if worksInBase(age, candidate):
        bestBase = candidate
        break
      candidate -= 1
  else:
    for tryBase in 11 .. 1000000:
      if worksInBase(age, int64(tryBase)):
        bestBase = int64(tryBase)
    var testDecimal = lower
    while testDecimal < 1000:
      let candidate = baseForDecimalValue(age, testDecimal)
      if candidate >= 10:
        if candidate > bestBase:
          bestBase = candidate
        break
      testDecimal += 1
  appendOutput($bestBase)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
