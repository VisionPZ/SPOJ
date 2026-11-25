const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc readLineBounds(data: string, pos: var int): tuple[first, last: int] =
  var lineStart = pos
  while lineStart < data.len and (data[lineStart] == '\n' or data[lineStart] == '\r'):
    inc lineStart
  var lineEnd = lineStart
  while lineEnd < data.len and data[lineEnd] != '\n' and data[lineEnd] != '\r':
    inc lineEnd
  pos = lineEnd
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    inc pos
  result = (lineStart, lineEnd)

proc nextNameToken(data: string, pos: var int, lineEnd: int): string =
  while pos < lineEnd and data[pos] <= ' ':
    inc pos
  if pos >= lineEnd:
    return ""
  let tokenStart = pos
  while pos < lineEnd and data[pos] > ' ':
    inc pos
  return data[tokenStart .. pos - 1]

proc nextNumberInLine(data: string, pos: var int, lineEnd: int): int =
  while pos < lineEnd and (data[pos] < '0' or data[pos] > '9'):
    inc pos
  var value = 0
  while pos < lineEnd and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    inc pos
  return value

proc isPrimeValue(value: int): bool =
  if value < 2:
    return false
  var divisor = 2
  while divisor * divisor <= value:
    if value mod divisor == 0:
      return false
    inc divisor
  return true

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

var lineBounds = readLineBounds(inputData, scanPos)
var countCursor = lineBounds.first
let participantCount = nextNumberInLine(inputData, countCursor, lineBounds.last)

lineBounds = readLineBounds(inputData, scanPos)
var nameCursor = lineBounds.first
var names = newSeq[string](participantCount)
for index in 0..<participantCount:
  names[index] = nextNameToken(inputData, nameCursor, lineBounds.last)

lineBounds = readLineBounds(inputData, scanPos)
var valueCursor = lineBounds.first
var enteredValues = newSeq[int](participantCount)
for index in 0..<participantCount:
  enteredValues[index] = nextNumberInLine(inputData, valueCursor, lineBounds.last)

lineBounds = readLineBounds(inputData, scanPos)
var targetCursor = lineBounds.first
let targetValue = nextNumberInLine(inputData, targetCursor, lineBounds.last)

var haveAbove = false
var bestAbove = 0
var bestIndex = 0
var largestBelow = -1
var largestBelowIndex = 0
for index in 0..<participantCount:
  let currentValue = enteredValues[index]
  var neighborValue: int
  if participantCount == 1:
    neighborValue = currentValue
  elif index == participantCount - 1:
    neighborValue = enteredValues[index - 1]
  else:
    neighborValue = enteredValues[index + 1]
  var result: int
  if isPrimeValue(currentValue):
    result = currentValue + neighborValue
  else:
    result = currentValue - neighborValue
  if result < 0:
    result = -result
  if result >= targetValue:
    if not haveAbove or result < bestAbove:
      haveAbove = true
      bestAbove = result
      bestIndex = index
  elif result > largestBelow:
    largestBelow = result
    largestBelowIndex = index

if not haveAbove:
  bestIndex = largestBelowIndex

appendOutput(names[bestIndex])
appendOutput(" ")
appendOutput($(enteredValues[bestIndex]))
appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
