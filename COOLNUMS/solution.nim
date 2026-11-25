import tables

const flushBlockBytes = 1 shl 17
const digitCount = 10
const highestSumBit = 27

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

var basePowers = newSeq[int](digitCount)
basePowers[0] = 1
for digit in 1 .. digitCount - 1:
  basePowers[digit] = basePowers[digit - 1] * 11

const highMask = (1'u64 shl highestSumBit) - 1'u64

proc addDigit(lowBits: uint64, highBits: uint64, digit: int): tuple[low: uint64, high: uint64] =
  if digit == 0:
    return (lowBits, highBits)
  let carry = lowBits shr (64 - digit)
  let newLow = lowBits or (lowBits shl digit)
  let newHigh = (highBits or (highBits shl digit) or carry) and highMask
  return (newLow, newHigh)

var completionCache = initTable[int64, int64]()

proc highestReachableSum(lowBits: uint64, highBits: uint64): int =
  if highBits != 0'u64:
    var bitIndex = 63
    while bitIndex >= 0 and (highBits and (1'u64 shl uint(bitIndex))) == 0'u64:
      bitIndex -= 1
    return 64 + bitIndex
  var bitIndex = 63
  while bitIndex >= 0 and (lowBits and (1'u64 shl uint(bitIndex))) == 0'u64:
    bitIndex -= 1
  return bitIndex

proc isCoolState(lowBits: uint64, highBits: uint64): int =
  let total = highestReachableSum(lowBits, highBits)
  if total mod 2 == 1:
    return 0
  let target = total div 2
  if target < 64:
    if (lowBits and (1'u64 shl uint(target))) != 0'u64:
      return 1
    return 0
  if (highBits and (1'u64 shl uint(target - 64))) != 0'u64:
    return 1
  return 0

proc countCompletions(remaining: int, code: int64, lowBits: uint64, highBits: uint64): int64 =
  if remaining == 0:
    return int64(isCoolState(lowBits, highBits))
  if completionCache.hasKey(code):
    return completionCache[code]
  var ways: int64 = 0
  for digit in 0 .. digitCount - 1:
    let shifted = addDigit(lowBits, highBits, digit)
    ways += countCompletions(remaining - 1, code + int64(basePowers[digit]),
                             shifted.low, shifted.high)
  completionCache[code] = ways
  return ways

proc countUpTo(limit: int64): int64 =
  if limit < 0:
    return 0
  var digits = newSeq[int](digitCount)
  var remainder = limit
  for position in countdown(digitCount - 1, 0):
    digits[position] = int(remainder mod 10)
    remainder = remainder div 10
  var answer: int64 = 0
  var lowBits = 1'u64
  var highBits = 0'u64
  var code: int64 = 0
  for position in 0 .. digitCount - 1:
    let currentDigit = digits[position]
    let remaining = digitCount - 1 - position
    for digit in 0 .. currentDigit - 1:
      let shifted = addDigit(lowBits, highBits, digit)
      answer += countCompletions(remaining, code + int64(basePowers[digit]),
                                 shifted.low, shifted.high)
    let shifted = addDigit(lowBits, highBits, currentDigit)
    lowBits = shifted.low
    highBits = shifted.high
    code += int64(basePowers[currentDigit])
  answer += countCompletions(0, code, lowBits, highBits)
  return answer

var lowerBound = int64(nextInt(inputData, scanPos))
var upperBound = int64(nextInt(inputData, scanPos))
while not (lowerBound == 0 and upperBound == 0):
  let answer = countUpTo(upperBound) - countUpTo(lowerBound - 1)
  appendOutput($answer)
  outputBuffer.add '\n'
  lowerBound = int64(nextInt(inputData, scanPos))
  upperBound = int64(nextInt(inputData, scanPos))

stdout.write outputBuffer
outputBuffer.setLen 0
