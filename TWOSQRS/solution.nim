const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const primeLimit = 1000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int64 =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value: int64 = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int64(int(data[position]) - firstDigitValue)
    position += 1
  return value

var isComposite = newSeq[bool](primeLimit + 1)
var primes: seq[int] = @[]
for candidate in 2..primeLimit:
  if not isComposite[candidate]:
    primes.add candidate
    if int64(candidate) * int64(candidate) <= primeLimit:
      var multiple = candidate * candidate
      while multiple <= primeLimit:
        isComposite[multiple] = true
        multiple += candidate

proc isSumOfTwoSquares(value: int64): bool =
  var remaining = value
  for prime in primes:
    let primeValue = int64(prime)
    if primeValue * primeValue > remaining:
      break
    if remaining mod primeValue != 0:
      continue
    var exponent = 0
    while remaining mod primeValue == 0:
      remaining = remaining div primeValue
      exponent += 1
    if primeValue mod 4 == 3 and (exponent and 1) == 1:
      return false
  if remaining > 1 and remaining mod 4 == 3:
    return false
  return true

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt(inputData, scanPos))
for caseIndex in 0..<caseCount:
  let value = nextInt(inputData, scanPos)
  if isSumOfTwoSquares(value):
    appendOutput("Yes")
  else:
    appendOutput("No")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
