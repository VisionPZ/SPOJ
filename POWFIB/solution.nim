const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007
const searchWindow = 200

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

var fibonacciValues = newSeq[int64]()
var lowerFib: int64 = 1
var upperFib: int64 = 1
while lowerFib <= 2000000000:
  if fibonacciValues.len == 0 or fibonacciValues[fibonacciValues.len - 1] != lowerFib:
    fibonacciValues.add lowerFib
  let followingFib = lowerFib + upperFib
  lowerFib = upperFib
  upperFib = followingFib

proc fibonacciPair(index: int64): (int64, int64) =
  if index == 0:
    return (int64(0), int64(1))
  let halfIndex = index div 2
  let (halfValue, halfNext) = fibonacciPair(halfIndex)
  let doubledNext = (2 * halfNext) mod modulusValue
  let correction = (doubledNext - halfValue + modulusValue) mod modulusValue
  let evenValue = (halfValue * correction) mod modulusValue
  let oddValue = (halfValue * halfValue + halfNext * halfNext) mod modulusValue
  if (index mod 2) == 0:
    return (evenValue, oddValue)
  return (oddValue, (evenValue + oddValue) mod modulusValue)

proc countFibonacciUpTo(limit: int64): int =
  var leftBound = 0
  var rightBound = fibonacciValues.len
  while leftBound < rightBound:
    let middle = (leftBound + rightBound) div 2
    if fibonacciValues[middle] <= limit:
      leftBound = middle + 1
    else:
      rightBound = middle
  return leftBound

proc nonFibonacciAtRank(rank: int64): int64 =
  var leftBound = rank
  var rightBound = rank + searchWindow
  while leftBound < rightBound:
    let middle = (leftBound + rightBound) div 2
    let skipped = int64(countFibonacciUpTo(middle))
    if middle - skipped >= rank:
      rightBound = middle
    else:
      leftBound = middle + 1
  return leftBound

proc powerModulo(baseValue: int64, exponent: int64): int64 =
  var runningBase = baseValue mod modulusValue
  var runningExponent = exponent
  var resultValue: int64 = 1
  while runningExponent > 0:
    if (runningExponent mod 2) == 1:
      resultValue = (resultValue * runningBase) mod modulusValue
    runningBase = (runningBase * runningBase) mod modulusValue
    runningExponent = runningExponent div 2
  return resultValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rankValue = int64(nextInt(inputData, scanPos))
  let nonFibValue = nonFibonacciAtRank(rankValue)
  let (fibValue, ignoredNext) = fibonacciPair(rankValue)
  let answerValue = powerModulo(nonFibValue, fibValue)
  appendOutput($answerValue)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
