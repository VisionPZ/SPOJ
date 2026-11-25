const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let elementCount = nextInt(inputData, scanPos)
var distinctValues: array[4, int]
var distinctCount = 0
for elementIndex in 0..<elementCount:
  let currentValue = nextInt(inputData, scanPos)
  var alreadySeen = false
  for slotIndex in 0..<distinctCount:
    if distinctValues[slotIndex] == currentValue:
      alreadySeen = true
      break
  if not alreadySeen and distinctCount < 4:
    distinctValues[distinctCount] = currentValue
    distinctCount += 1

var canEqualize = false
if distinctCount <= 2:
  canEqualize = true
elif distinctCount == 3:
  var firstValue = distinctValues[0]
  var secondValue = distinctValues[1]
  var thirdValue = distinctValues[2]
  if firstValue > secondValue:
    swap firstValue, secondValue
  if secondValue > thirdValue:
    swap secondValue, thirdValue
  if firstValue > secondValue:
    swap firstValue, secondValue
  canEqualize = firstValue + thirdValue == 2 * secondValue

if canEqualize:
  appendOutput("Si\n")
else:
  appendOutput("No\n")

stdout.write outputBuffer
outputBuffer.setLen 0
