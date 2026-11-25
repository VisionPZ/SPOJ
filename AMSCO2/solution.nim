const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc chunkSize(rowIndex: int, columnIndex: int): int =
  if (rowIndex + columnIndex) mod 2 == 0:
    return 2
  return 1

while scanPos < inputData.len:
  let keyToken = nextToken(inputData, scanPos)
  if keyToken.len == 0:
    break
  let cipherToken = nextToken(inputData, scanPos)
  let keyLength = keyToken.len
  var keyLabels = newSeq[int](keyLength)
  for digitIndex in 0 .. keyLength - 1:
    keyLabels[digitIndex] = int(keyToken[digitIndex]) - 48

  var evenRowLength = 0
  var oddRowLength = 0
  for columnIndex in 0 .. keyLength - 1:
    evenRowLength = evenRowLength + chunkSize(0, columnIndex)
    oddRowLength = oddRowLength + chunkSize(1, columnIndex)

  var fullRows = 0
  var tailLength = cipherToken.len
  while true:
    let rowLength = if fullRows mod 2 == 0: evenRowLength else: oddRowLength
    if tailLength < rowLength:
      break
    tailLength = tailLength - rowLength
    fullRows = fullRows + 1

  var lastColumns = 0
  var usedInTail = 0
  var prefixBeforeLast = 0
  for columnIndex in 0 .. keyLength - 1:
    usedInTail = usedInTail + chunkSize(fullRows, columnIndex)
    lastColumns = lastColumns + 1
    if usedInTail >= tailLength:
      break
    prefixBeforeLast = prefixBeforeLast + chunkSize(fullRows, columnIndex)

  var columnLengths = newSeq[int](keyLength)
  for columnIndex in 0 .. keyLength - 1:
    var total = 0
    for rowIndex in 0 .. fullRows - 1:
      total = total + chunkSize(rowIndex, columnIndex)
    if columnIndex < lastColumns - 1:
      total = total + chunkSize(fullRows, columnIndex)
    elif columnIndex == lastColumns - 1:
      total = total + tailLength - prefixBeforeLast
    columnLengths[columnIndex] = total

  var columnTexts = newSeq[string](keyLength)
  var cipherPos = 0
  for label in 1 .. keyLength:
    var targetColumn = 0
    for columnIndex in 0 .. keyLength - 1:
      if keyLabels[columnIndex] == label:
        targetColumn = columnIndex
        break
    for offset in 0 .. columnLengths[targetColumn] - 1:
      columnTexts[targetColumn].add cipherToken[cipherPos + offset]
    cipherPos = cipherPos + columnLengths[targetColumn]

  var columnPos = newSeq[int](keyLength)
  var lastRow = fullRows
  if lastColumns > 0:
    lastRow = fullRows + 1
  var plainText = ""
  for rowIndex in 0 .. lastRow - 1:
    for columnIndex in 0 .. keyLength - 1:
      if rowIndex == fullRows and columnIndex >= lastColumns:
        break
      var size = chunkSize(rowIndex, columnIndex)
      if rowIndex == fullRows and columnIndex == lastColumns - 1:
        size = columnTexts[columnIndex].len - columnPos[columnIndex]
      for offset in 0 .. size - 1:
        plainText.add columnTexts[columnIndex][columnPos[columnIndex] + offset]
      columnPos[columnIndex] = columnPos[columnIndex] + size
  appendOutput(plainText)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
