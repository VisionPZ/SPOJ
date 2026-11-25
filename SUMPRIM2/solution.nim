import math

{.push checks: off.}

const flushBlockBytes = 1 shl 17
const limbMask = 4294967295'u64
const windowRadius = 1000000'i64

type Wide = object
  lo: uint64
  hi: uint64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc makeWide(value: int64): Wide =
  Wide(lo: uint64(value), hi: 0'u64)

proc addWide(first: Wide, second: Wide): Wide =
  let lowPart = first.lo + second.lo
  var carry = 0'u64
  if lowPart < first.lo: carry = 1
  Wide(lo: lowPart, hi: first.hi + second.hi + carry)

proc subWide(first: Wide, second: Wide): Wide =
  let lowPart = first.lo - second.lo
  var borrow = 0'u64
  if first.lo < second.lo: borrow = 1
  Wide(lo: lowPart, hi: first.hi - second.hi - borrow)

proc cmpWide(first: Wide, second: Wide): int =
  if first.hi != second.hi:
    if first.hi < second.hi: return -1
    return 1
  if first.lo < second.lo: return -1
  if first.lo > second.lo: return 1
  return 0

proc toFloatWide(value: Wide): float =
  return float(value.hi) * 18446744073709551616.0 + float(value.lo)

proc addDigit(value: var Wide, digit: int64) =
  let newLow = value.lo + uint64(digit)
  if newLow < value.lo: value.hi += 1
  value.lo = newLow

proc mulSmall(value: Wide, factor: int64): Wide =
  let factorValue = uint64(factor)
  let lowHalf = value.lo and limbMask
  let highHalf = value.lo shr 32
  let bottomPart = lowHalf * factorValue
  let topPart = highHalf * factorValue
  let newLow = bottomPart + (topPart shl 32)
  var carry = topPart shr 32
  if newLow < bottomPart: carry += 1
  Wide(lo: newLow, hi: value.hi * factorValue + carry)

proc productWide(first: int64, second: int64): Wide =
  let firstValue = uint64(first)
  let secondValue = uint64(second)
  let firstLow = firstValue and limbMask
  let firstHigh = firstValue shr 32
  let secondLow = secondValue and limbMask
  let secondHigh = secondValue shr 32
  let bottomPart = firstLow * secondLow
  let crossPart = firstLow * secondHigh + firstHigh * secondLow
  let newLow = bottomPart + (crossPart shl 32)
  var carry = crossPart shr 32
  if newLow < bottomPart: carry += 1
  Wide(lo: newLow, hi: firstHigh * secondHigh + carry)

proc triangleWide(value: int64): Wide =
  if value < 2: return makeWide(0)
  let half = if value mod 2 == 0: value div 2 else: (value + 1) div 2
  let other = if value mod 2 == 0: value + 1 else: value
  return subWide(productWide(half, other), makeWide(1))

proc parseWide(data: string, pos: var int): Wide =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  result = makeWide(0)
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result = mulSmall(result, 10)
    addDigit(result, int64(int(data[pos]) - 48))
    pos += 1

proc smallPrimes(limit: int64): seq[int64] =
  var composite = newSeq[bool](int(limit) + 1)
  result = newSeq[int64](0)
  for value in 2 .. int(limit):
    if not composite[value]:
      result.add int64(value)
      var multiple = value * value
      while multiple <= int(limit):
        composite[multiple] = true
        multiple += value

proc primeSum(limit: int64): Wide =
  if limit < 2: return makeWide(0)
  var root = int64(sqrt(float(limit)))
  while (root + 1) * (root + 1) <= limit: root += 1
  while root * root > limit: root -= 1
  let primes = smallPrimes(root)
  var smallSum = newSeq[int64](int(root) + 1)
  for value in 2 .. int(root):
    smallSum[value] = value * (value + 1) div 2 - 1
  var largeSum = newSeq[Wide](int(root) + 1)
  for divisor in 1 .. int(root):
    largeSum[divisor] = triangleWide(limit div int64(divisor))
  var primePrefix = newSeq[int64](int(root) + 1)
  var running = 0'i64
  var primeIndex = 0
  for value in 0 .. int(root):
    while primeIndex < primes.len and primes[primeIndex] <= int64(value):
      running += primes[primeIndex]
      primeIndex += 1
    primePrefix[value] = running
  for prime in primes:
    let square = prime * prime
    let beforePrime = primePrefix[int(prime) - 1]
    let beforeWide = makeWide(beforePrime)
    let maxDivisor = min(root, limit div square)
    let primeValue = int(prime)
    let splitDivisor = min(int(maxDivisor), int(root) div primeValue)
    if splitDivisor >= 1:
      for divisor in 1 .. splitDivisor:
        let quotientSum = largeSum[divisor * primeValue]
        let removed = mulSmall(subWide(quotientSum, beforeWide), prime)
        largeSum[divisor] = subWide(largeSum[divisor], removed)
    if splitDivisor < int(maxDivisor):
      for divisor in splitDivisor + 1 .. int(maxDivisor):
        let quotientIndex = int64(divisor) * prime
        let quotientSum = makeWide(int64(smallSum[int(limit div quotientIndex)]))
        let removed = mulSmall(subWide(quotientSum, beforeWide), prime)
        largeSum[divisor] = subWide(largeSum[divisor], removed)
    var value = int(root)
    while int64(value) >= square:
      let quotient = value div primeValue
      smallSum[value] -= primeValue * (smallSum[quotient] - beforePrime)
      value -= 1
  return largeSum[1]

proc liApproximation(value: float): float =
  let logarithm = ln(value)
  let denominator = 2.0 * logarithm
  var power = 1.0
  var total = 1.0
  var factorial = 1.0
  for order in 1 .. 14:
    factorial *= float(order)
    power /= denominator
    total += factorial * power
  return value * value / denominator * total

proc estimateRoot(target: float): int64 =
  var guess = sqrt(2.0 * target * ln(max(target, 2.0)))
  for iteration in 0 .. 9:
    let safeGuess = max(guess, 2.0)
    guess = safeGuess - (liApproximation(safeGuess) - target) * ln(safeGuess) / safeGuess
    if guess < 2.0: guess = 2.0
  return int64(guess)

proc nearbyPrimes(center: int64): seq[int64] =
  let low = max(2'i64, center - windowRadius)
  let high = center + windowRadius
  let span = int(high - low + 1)
  var marked = newSeq[bool](span)
  let root = int64(sqrt(float(high))) + 1
  let basePrimes = smallPrimes(root)
  for prime in basePrimes:
    if prime * prime > high: break
    let square = prime * prime
    var start = ((low + prime - 1) div prime) * prime
    if start < square: start = square
    var multiple = start
    while multiple <= high:
      marked[int(multiple - low)] = true
      multiple += prime
  result = newSeq[int64](0)
  for offset in 0 .. span - 1:
    if not marked[offset]:
      result.add low + int64(offset)

let targetSum = parseWide(inputData, scanPos)
var candidate = estimateRoot(toFloatWide(targetSum))
if candidate < 2: candidate = 2
var sumAtCandidate = primeSum(candidate)
var answer = 0'i64

proc searchWindow(center: int64, startingSum: Wide): int64 =
  let localPrimes = nearbyPrimes(center)
  var anchor = -1
  for primeIndex in 0 .. localPrimes.len - 1:
    if localPrimes[primeIndex] <= center: anchor = primeIndex
  if anchor < 0: return 0
  var runningSum = startingSum
  if cmpWide(runningSum, targetSum) == 0:
    return localPrimes[anchor]
  var upward = anchor + 1
  while upward < localPrimes.len:
    runningSum = addWide(runningSum, makeWide(localPrimes[upward]))
    if cmpWide(runningSum, targetSum) == 0:
      return localPrimes[upward]
    upward += 1
  runningSum = startingSum
  var downward = anchor - 1
  while downward >= 0:
    runningSum = subWide(runningSum, makeWide(localPrimes[downward + 1]))
    if cmpWide(runningSum, targetSum) == 0:
      return localPrimes[downward]
    downward -= 1
  return 0

answer = searchWindow(candidate, sumAtCandidate)

if answer == 0:
  let difference = toFloatWide(targetSum) - toFloatWide(sumAtCandidate)
  let corrected = float(candidate) + difference * ln(float(candidate)) / float(candidate)
  candidate = int64(max(2.0, corrected))
  sumAtCandidate = primeSum(candidate)
  answer = searchWindow(candidate, sumAtCandidate)

if answer == 0:
  var lower = 2'i64
  var upper = candidate * 2
  if upper < 4: upper = 4
  while lower < upper:
    let middle = (lower + upper) div 2
    if cmpWide(primeSum(middle), targetSum) < 0:
      lower = middle + 1
    else:
      upper = middle
  candidate = lower
  sumAtCandidate = primeSum(candidate)
  answer = searchWindow(candidate, sumAtCandidate)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
