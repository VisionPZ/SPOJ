const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const witnessBases: array[12, uint64] = [2'u64, 3'u64, 5'u64, 7'u64, 11'u64, 13'u64,
                                         17'u64, 19'u64, 23'u64, 29'u64, 31'u64, 37'u64]

proc nextUint(data: string, i: var int): uint64 =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0'u64
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10'u64 + uint64(int(data[i]) - firstDigitValue)
    i += 1
  return value

proc modMultiply(leftValue, rightValue, modulusValue: uint64): uint64 =
  var doubled = leftValue mod modulusValue
  var remaining = rightValue
  var product = 0'u64
  while remaining != 0'u64:
    if (remaining and 1'u64) != 0'u64:
      product = product + doubled
      if product >= modulusValue: product = product - modulusValue
    remaining = remaining shr 1
    doubled = doubled shl 1
    if doubled >= modulusValue: doubled = doubled - modulusValue
  return product

proc modularPower(baseValue, exponentValue, modulusValue: uint64): uint64 =
  var factor = baseValue mod modulusValue
  var power = 1'u64
  var exponent = exponentValue
  while exponent != 0'u64:
    if (exponent and 1'u64) != 0'u64:
      power = modMultiply(power, factor, modulusValue)
    factor = modMultiply(factor, factor, modulusValue)
    exponent = exponent shr 1
  return power

proc isPrime(candidate: uint64): bool =
  if candidate < 2'u64: return false
  for primeBase in witnessBases:
    if candidate == primeBase: return true
    if candidate mod primeBase == 0'u64: return false
  var oddPart = candidate - 1'u64
  var twosCount = 0
  while (oddPart and 1'u64) == 0'u64:
    oddPart = oddPart shr 1
    twosCount += 1
  for primeBase in witnessBases:
    var term = modularPower(primeBase, oddPart, candidate)
    if term == 1'u64 or term == candidate - 1'u64: continue
    var witnessed = false
    var roundIndex = 1
    while roundIndex < twosCount:
      term = modMultiply(term, term, candidate)
      if term == candidate - 1'u64:
        witnessed = true
        break
      roundIndex += 1
    if not witnessed: return false
  return true

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let caseCount = int(nextUint(inputData, i))
var outputBuffer = ""

var caseIndex = 0
while caseIndex < caseCount:
  let candidate = nextUint(inputData, i)
  if isPrime(candidate):
    outputBuffer.add "YES\n"
  else:
    outputBuffer.add "NO\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  caseIndex += 1

stdout.write outputBuffer
