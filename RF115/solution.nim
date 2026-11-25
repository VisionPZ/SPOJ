const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return 0
  var negative = false
  if data[pos] == '-':
    negative = true
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    value = -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let dimensionValue = nextInt(inputData, scanPos)
let categoryValue = nextInt(inputData, scanPos)
let dimension = int(dimensionValue)
var totalSum: int64 = 0
var largestValue: int64 = -1000000000000
var smallestValue: int64 = 1000000000000
for rowIndex in 0 .. dimension - 1:
  for columnIndex in 0 .. dimension - 1:
    if columnIndex != 0:
      appendOutput(" ")
    let cellValue = int64(rowIndex) + int64(columnIndex) - categoryValue
    appendOutput($cellValue)
    totalSum += cellValue
    if cellValue > largestValue:
      largestValue = cellValue
    if cellValue < smallestValue:
      smallestValue = cellValue
  appendOutput("\n")
if dimension > 0:
  appendOutput($totalSum)
  appendOutput("\n")
  appendOutput($largestValue)
  appendOutput("\n")
  appendOutput($smallestValue)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
