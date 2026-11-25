const flushBlockBytes = 1 shl 17
const largestFactorBase = 31623

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

proc hasNextNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var isComposite = newSeq[bool](largestFactorBase + 1)
var primes = newSeq[int]()
for candidate in 2 .. largestFactorBase:
  if not isComposite[candidate]:
    primes.add candidate
    let stride = candidate * candidate
    if stride <= largestFactorBase:
      var multiple = stride
      while multiple <= largestFactorBase:
        isComposite[multiple] = true
        multiple = multiple + candidate

proc divisorData(value: int): tuple[count: int64, sum: int64] =
  if value == 0:
    return (0.int64, 0.int64)
  var remaining = value
  var count: int64 = 1
  var divisorSum: int64 = 1
  for prime in primes:
    if prime * prime > remaining:
      break
    if remaining mod prime == 0:
      var exponent = 0
      var power = 1
      while remaining mod prime == 0:
        remaining = remaining div prime
        exponent += 1
        power = power * prime
      count = count * (exponent + 1)
      divisorSum = divisorSum * (power * prime - 1) div (prime - 1)
  if remaining > 1:
    count = count * 2
    divisorSum = divisorSum * (remaining + 1)
  return (count, divisorSum)

proc nextPermutation(digits: var seq[int]): bool =
  let digitCount = digits.len
  var pivot = digitCount - 2
  while pivot >= 0 and digits[pivot] >= digits[pivot + 1]:
    pivot -= 1
  if pivot < 0:
    return false
  var successor = digitCount - 1
  while digits[successor] <= digits[pivot]:
    successor -= 1
  swap digits[pivot], digits[successor]
  var leftIndex = pivot + 1
  var rightIndex = digitCount - 1
  while leftIndex < rightIndex:
    swap digits[leftIndex], digits[rightIndex]
    leftIndex += 1
    rightIndex -= 1
  return true

while hasNextNumber(inputData, scanPos):
  let digitCount = nextInt(inputData, scanPos)
  var digits = newSeq[int](digitCount)
  for digitIndex in 0 .. digitCount - 1:
    digits[digitIndex] = nextInt(inputData, scanPos)
  for firstIndex in 1 .. digitCount - 1:
    let held = digits[firstIndex]
    var previousIndex = firstIndex - 1
    while previousIndex >= 0 and digits[previousIndex] > held:
      digits[previousIndex + 1] = digits[previousIndex]
      previousIndex -= 1
    digits[previousIndex + 1] = held
  var bestCount: int64 = -1
  var bestSum: int64 = -1
  var bestCountNumber = 0
  var bestSumNumber = 0
  while true:
    var assembled = 0
    for digit in digits:
      assembled = assembled * 10 + digit
    let data = divisorData(assembled)
    if data.count > bestCount or (data.count == bestCount and assembled < bestCountNumber):
      bestCount = data.count
      bestCountNumber = assembled
    if data.sum > bestSum or (data.sum == bestSum and assembled < bestSumNumber):
      bestSum = data.sum
      bestSumNumber = assembled
    if not nextPermutation(digits):
      break
  appendOutput($bestCountNumber & " " & $bestSumNumber)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
