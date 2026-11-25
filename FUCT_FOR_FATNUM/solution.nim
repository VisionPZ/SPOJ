import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxDigits = 7

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

var fatNumbers: seq[int] = @[]

proc intPow(base: int, exponent: int): int =
  var powerValue = 1
  for powerIndex in 0..<exponent:
    powerValue *= base
  return powerValue

proc buildPermutations(digitCounts: var array[1..9, int], digitsLeft: int, prefixValue: int) =
  if digitsLeft == 0:
    fatNumbers.add prefixValue
    return
  for digit in 1..9:
    if digitCounts[digit] > 0:
      digitCounts[digit] -= 1
      buildPermutations(digitCounts, digitsLeft - 1, prefixValue * 10 + digit)
      digitCounts[digit] += 1

proc collectMultisets(digit: int, digitsLeft: int, digitSum: int, digitProduct: int, digitCounts: var array[1..9, int]) =
  if digit == 10:
    if digitSum > 0 and digitSum == digitProduct:
      buildPermutations(digitCounts, maxDigits - digitsLeft, 0)
    return
  var taken = 0
  while taken <= digitsLeft:
    digitCounts[digit] = taken
    let nextSum = digitSum + taken * digit
    let nextProduct = digitProduct * intPow(digit, taken)
    if nextProduct <= nextSum + 9 * (digitsLeft - taken):
      collectMultisets(digit + 1, digitsLeft - taken, nextSum, nextProduct, digitCounts)
    digitCounts[digit] = 0
    taken += 1

var digitCounts: array[1..9, int]
collectMultisets(1, maxDigits, 0, 1, digitCounts)
sort(fatNumbers, cmp)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc lowerBound(values: seq[int], target: int): int =
  var leftIndex = 0
  var rightIndex = values.len
  while leftIndex < rightIndex:
    let middleIndex = (leftIndex + rightIndex) div 2
    if values[middleIndex] < target:
      leftIndex = middleIndex + 1
    else:
      rightIndex = middleIndex
  return leftIndex

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  var rangeStart = nextInt(inputData, scanPos)
  var rangeStop = nextInt(inputData, scanPos)
  if rangeStart > rangeStop:
    let swapValue = rangeStart
    rangeStart = rangeStop
    rangeStop = swapValue
  var firstIndex = lowerBound(fatNumbers, rangeStart)
  var lastIndex = lowerBound(fatNumbers, rangeStop + 1)
  var printedAny = false
  while firstIndex < lastIndex:
    if printedAny:
      appendOutput(" ")
    appendOutput($(fatNumbers[firstIndex]))
    printedAny = true
    firstIndex += 1
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
