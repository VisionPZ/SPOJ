const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, i: var int): int64 =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] != '-' and
      (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var negative = false
  if i < dataLength and inputData[i] == '-':
    negative = true
    i += 1
  var value: int64 = 0
  while i < dataLength and inputData[i] >= '0' and
      inputData[i] <= '9':
    value = value * 10 + int64(int(inputData[i]) - 48)
    i += 1
  if negative:
    value = -value
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let caseCount = int(nextInt(inputData, i))
var outputBuffer = ""

for j in 0 ..< caseCount:
  let sequenceLength = int(nextInt(inputData, i))
  let completionCount = int(nextInt(inputData, i))
  var differenceTable: seq[seq[int64]] = @[]
  var startingRow: seq[int64] = @[]
  startingRow.setLen(sequenceLength)
  for k in 0 ..< sequenceLength:
    startingRow[k] = nextInt(inputData, i)
  differenceTable.add startingRow
  while differenceTable[differenceTable.high].len > 1:
    let upperRow = differenceTable[differenceTable.high]
    let lowerLength = upperRow.len - 1
    var lowerRow: seq[int64] = @[]
    lowerRow.setLen(lowerLength)
    for k in 0 ..< lowerLength:
      lowerRow[k] = upperRow[k + 1] - upperRow[k]
    differenceTable.add lowerRow
  var lastElements: seq[int64] = @[]
  lastElements.setLen(differenceTable.len)
  for k in 0 ..< differenceTable.len:
    lastElements[k] = differenceTable[k][differenceTable[k].high]
  for l in 0 ..< completionCount:
    var carriedValue = lastElements[lastElements.high]
    var k = lastElements.high - 1
    while k >= 0:
      carriedValue = lastElements[k] + carriedValue
      lastElements[k] = carriedValue
      k -= 1
    if l > 0:
      outputBuffer.add ' '
    outputBuffer.add $carriedValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
