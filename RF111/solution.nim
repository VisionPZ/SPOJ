const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const separatorMark = ';'

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLineBounds(data: string, pos: var int): tuple[first, last: int] =
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

proc nextNumberInRange(data: string, pos: var int, limit: int): int64 =
  while pos < limit and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    inc pos
  if pos >= limit:
    return 0
  var negative = false
  if data[pos] == '-':
    negative = true
    inc pos
  var value: int64 = 0
  while pos < limit and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    inc pos
  if negative:
    value = -value
  return value

proc collectNumbers(data: string, startPos: int, limit: int,
                    values: var seq[int64]) =
  var cursor = startPos
  while cursor < limit:
    while cursor < limit and (data[cursor] < '0' or data[cursor] > '9') and
        data[cursor] != '-':
      inc cursor
    if cursor >= limit:
      break
    values.add nextNumberInRange(data, cursor, limit)

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

while scanPos < inputData.len:
  let lineBounds = nextLineBounds(inputData, scanPos)
  let lineStart = lineBounds.first
  let lineEnd = lineBounds.last
  var hasContent = false
  for position in lineStart..<lineEnd:
    if inputData[position] > ' ':
      hasContent = true
      break
  if not hasContent:
    continue

  var separator = lineStart
  while separator < lineEnd and inputData[separator] != separatorMark:
    inc separator
  if separator >= lineEnd:
    continue

  var matrixValues: seq[int64] = @[]
  var weightValues: seq[int64] = @[]
  collectNumbers(inputData, lineStart, separator, matrixValues)
  collectNumbers(inputData, separator + 1, lineEnd, weightValues)

  let columnCount = weightValues.len
  if columnCount == 0:
    continue

  var priceValues: seq[int64] = @[]
  var lowestPrice: int64 = 0
  var rowStart = 0
  var firstRow = true
  while rowStart + columnCount <= matrixValues.len:
    var rowTotal: int64 = 0
    for column in 0..<columnCount:
      rowTotal += matrixValues[rowStart + column] * weightValues[column]
    priceValues.add rowTotal
    if firstRow or rowTotal < lowestPrice:
      lowestPrice = rowTotal
      firstRow = false
    rowStart += columnCount

  if priceValues.len == 0:
    continue

  outputBuffer.add '"'
  outputBuffer.add '{'
  for priceIndex in 0..<priceValues.len:
    if priceIndex > 0:
      outputBuffer.add ','
    outputBuffer.add $(priceValues[priceIndex])
  outputBuffer.add '}'
  outputBuffer.add ' '
  outputBuffer.add "\xE2\x80\x93"
  outputBuffer.add ' '
  outputBuffer.add $(lowestPrice)
  outputBuffer.add '"'
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
