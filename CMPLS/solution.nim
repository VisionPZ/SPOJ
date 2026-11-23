const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int64 =
  let dataLength = inputData.len
  while scanPos < dataLength and inputData[scanPos] != '-' and
      (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var negative = false
  if scanPos < dataLength and inputData[scanPos] == '-':
    negative = true
    scanPos += 1
  var value: int64 = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and
      inputData[scanPos] <= '9':
    value = value * 10 + int64(int(inputData[scanPos]) - 48)
    scanPos += 1
  if negative:
    value = -value
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = int(nextInt(inputData, scanPos))
var outputBuffer = ""

for caseIndex in 0 ..< caseCount:
  let sequenceLength = int(nextInt(inputData, scanPos))
  let completionCount = int(nextInt(inputData, scanPos))
  var differenceTable: seq[seq[int64]] = @[]
  var startingRow: seq[int64] = @[]
  startingRow.setLen(sequenceLength)
  for position in 0 ..< sequenceLength:
    startingRow[position] = nextInt(inputData, scanPos)
  differenceTable.add startingRow
  while differenceTable[differenceTable.high].len > 1:
    let upperRow = differenceTable[differenceTable.high]
    let lowerLength = upperRow.len - 1
    var lowerRow: seq[int64] = @[]
    lowerRow.setLen(lowerLength)
    for position in 0 ..< lowerLength:
      lowerRow[position] = upperRow[position + 1] - upperRow[position]
    differenceTable.add lowerRow
  var lastElements: seq[int64] = @[]
  lastElements.setLen(differenceTable.len)
  for rowIndex in 0 ..< differenceTable.len:
    lastElements[rowIndex] = differenceTable[rowIndex][differenceTable[rowIndex].high]
  for completionIndex in 0 ..< completionCount:
    var carriedValue = lastElements[lastElements.high]
    var rowIndex = lastElements.high - 1
    while rowIndex >= 0:
      carriedValue = lastElements[rowIndex] + carriedValue
      lastElements[rowIndex] = carriedValue
      rowIndex -= 1
    if completionIndex > 0:
      outputBuffer.add ' '
    outputBuffer.add $carriedValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
