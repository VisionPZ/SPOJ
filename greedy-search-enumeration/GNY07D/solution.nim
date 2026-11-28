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

proc nextBits(data: string, pos: var int): string =
  if pos < data.len and data[pos] == ' ':
    pos += 1
  var bits = ""
  while pos < data.len and data[pos] != '\n' and data[pos] != '\r':
    if data[pos] == '0' or data[pos] == '1':
      bits.add data[pos]
    pos += 1
  return bits

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let receivedBits = nextBits(inputData, scanPos)
  let cellCount = rowCount * columnCount
  var spiralRows = newSeq[int](cellCount)
  var spiralCols = newSeq[int](cellCount)
  var cellIndex = 0
  var topRow = 0
  var leftCol = 0
  var bottomRow = rowCount - 1
  var rightCol = columnCount - 1
  while topRow <= bottomRow and leftCol <= rightCol:
    var col = leftCol
    while col <= rightCol:
      spiralRows[cellIndex] = topRow
      spiralCols[cellIndex] = col
      cellIndex += 1
      col += 1
    topRow += 1
    var row = topRow
    while row <= bottomRow:
      spiralRows[cellIndex] = row
      spiralCols[cellIndex] = rightCol
      cellIndex += 1
      row += 1
    rightCol -= 1
    if topRow <= bottomRow:
      col = rightCol
      while col >= leftCol:
        spiralRows[cellIndex] = bottomRow
        spiralCols[cellIndex] = col
        cellIndex += 1
        col -= 1
      bottomRow -= 1
    if leftCol <= rightCol:
      row = bottomRow
      while row >= topRow:
        spiralRows[cellIndex] = row
        spiralCols[cellIndex] = leftCol
        cellIndex += 1
        row -= 1
      leftCol += 1
  var decoded = ""
  var groupValue = 0
  var groupBits = 0
  for index in 0 .. cellCount - 1:
    let cell = spiralRows[index] * columnCount + spiralCols[index]
    if cell < receivedBits.len:
      groupValue = groupValue * 2
      if receivedBits[cell] == '1':
        groupValue += 1
      groupBits += 1
      if groupBits == 5:
        if groupValue == 0:
          decoded.add ' '
        else:
          decoded.add chr(64 + groupValue)
        groupValue = 0
        groupBits = 0
  while decoded.len > 0 and decoded[decoded.len - 1] == ' ':
    decoded.setLen decoded.len - 1
  var line = $caseIndex & " " & decoded & "\n"
  appendOutput(line)

stdout.write outputBuffer
outputBuffer.setLen 0
