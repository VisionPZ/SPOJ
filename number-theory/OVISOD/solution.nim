const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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

proc gcdValues(firstValue, secondValue: int64): int64 =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

proc divisorSum(value: int64): int64 =
  var remaining = value
  var total = 1.int64
  var factor = 2.int64
  while factor * factor <= remaining:
    if remaining mod factor == 0:
      var power = 1.int64
      var term = 1.int64
      while remaining mod factor == 0:
        remaining = remaining div factor
        power = power * factor
        term += power
      total *= term
    factor += 1
  if remaining > 1:
    total *= 1 + remaining
  return total

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let numberCount = nextInt(inputData, scanPos)
  var commonDivisor = 0.int64
  for numberIndex in 0..<numberCount:
    let currentValue = int64(nextInt(inputData, scanPos))
    commonDivisor = gcdValues(commonDivisor, currentValue)
  appendOutput($(divisorSum(commonDivisor)) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
