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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextCell(data: string, pos: var int): char =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let cell = data[pos]
  pos += 1
  return cell

proc countBits(value: uint32): int =
  var remaining = value
  var count = 0
  while remaining != 0:
    count += int(remaining and uint32(1))
    remaining = remaining shr 1
  return count

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  var boardRows = newSeq[uint32](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    var rowMask = uint32(0)
    for columnIndex in 0 .. columnCount - 1:
      let cell = nextCell(inputData, scanPos)
      if cell == 'X':
        rowMask = rowMask or (uint32(1) shl uint32(columnIndex))
    boardRows[rowIndex] = rowMask
  let fullMask = (uint32(1) shl uint32(columnCount)) - uint32(1)
  let firstRowChoices = 1 shl columnCount
  var bestTaps = -1
  for firstRowPattern in 0 .. firstRowChoices - 1:
    var tapRows = newSeq[uint32](rowCount)
    tapRows[0] = uint32(firstRowPattern)
    for rowIndex in 0 .. rowCount - 2:
      let tapMask = tapRows[rowIndex]
      let sameRowFlip = tapMask xor ((tapMask shl 1) and fullMask) xor (tapMask shr 1)
      var aboveFlip = uint32(0)
      if rowIndex > 0:
        aboveFlip = tapRows[rowIndex - 1]
      tapRows[rowIndex + 1] = boardRows[rowIndex] xor sameRowFlip xor aboveFlip
    let lastRow = rowCount - 1
    let lastTapMask = tapRows[lastRow]
    let lastRowFlip = lastTapMask xor ((lastTapMask shl 1) and fullMask) xor (lastTapMask shr 1)
    var aboveFlip = uint32(0)
    if lastRow > 0:
      aboveFlip = tapRows[lastRow - 1]
    if (boardRows[lastRow] xor lastRowFlip xor aboveFlip) != uint32(0):
      continue
    var tapTotal = 0
    for rowIndex in 0 .. rowCount - 1:
      tapTotal += countBits(tapRows[rowIndex])
    if bestTaps == -1 or tapTotal < bestTaps:
      bestTaps = tapTotal
  if bestTaps == -1:
    appendOutput("Damaged billboard.")
  else:
    appendOutput("You have to tap " & $bestTaps & " tiles.")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
