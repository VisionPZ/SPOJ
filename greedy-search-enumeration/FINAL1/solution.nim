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

let columnCount = nextInt(inputData, scanPos)
var leftCounts: seq[int] = @[]
var rightCounts: seq[int] = @[]
var leftTotal = 0
var rightTotal = 0
for columnIndex in 0..<columnCount:
  let leftCount = nextInt(inputData, scanPos)
  let rightCount = nextInt(inputData, scanPos)
  leftCounts.add leftCount
  rightCounts.add rightCount
  leftTotal += leftCount
  rightTotal += rightCount

let currentDifference = leftTotal - rightTotal
var bestBeauty = abs(currentDifference)
var bestColumn = 0
for columnIndex in 0..<columnCount:
  let change = leftCounts[columnIndex] - rightCounts[columnIndex]
  let swappedDifference = currentDifference - 2 * change
  let swappedBeauty = abs(swappedDifference)
  if swappedBeauty > bestBeauty:
    bestBeauty = swappedBeauty
    bestColumn = columnIndex + 1

appendOutput($(bestColumn))
appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
