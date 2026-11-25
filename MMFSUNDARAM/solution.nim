const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxCompositeIndex = 50000

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendInteger(value: int) =
  var digits: array[12, char]
  var digitCount = 0
  var remaining = value
  while remaining > 0:
    digits[digitCount] = chr(remaining mod 10 + firstDigitValue)
    digitCount += 1
    remaining = remaining div 10
  for digitIndex in countdown(digitCount - 1, 0):
    outputBuffer.add digits[digitIndex]

proc appendPrime(value: int, isFirst: bool) =
  if not isFirst:
    outputBuffer.add ' '
  appendInteger(value)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let limit = nextInt(inputData, scanPos)
let halfLimit = (limit - 1) div 2
var composite: array[0..maxCompositeIndex, bool]
for leftIndex in 1..halfLimit:
  var rightIndex = leftIndex
  while leftIndex + rightIndex + 2 * leftIndex * rightIndex <= halfLimit:
    composite[leftIndex + rightIndex + 2 * leftIndex * rightIndex] = true
    rightIndex += 1

if limit >= 2:
  appendPrime(2, true)
for oddIndex in 1..halfLimit:
  if not composite[oddIndex]:
    appendPrime(2 * oddIndex + 1, false)

appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
