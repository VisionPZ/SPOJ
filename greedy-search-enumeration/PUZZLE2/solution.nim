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

proc nextColor(data: string, pos: var int): char =
  while pos < data.len and data[pos] != 'B' and data[pos] != 'R':
    pos += 1
  let foundColor = data[pos]
  pos += 1
  return foundColor

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc canonicalColumn(column: string): string =
  var complement = newSeq[char](column.len)
  for bitIndex in 0 .. column.len - 1:
    if column[bitIndex] == '1':
      complement[bitIndex] = '0'
    else:
      complement[bitIndex] = '1'
  var complementText = ""
  for bitIndex in 0 .. column.len - 1:
    complementText.add complement[bitIndex]
  if complementText < column:
    return complementText
  return column

proc sortColumns(columns: var seq[string]) =
  for rightIndex in 1 .. columns.len - 1:
    let carriedColumn = columns[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and columns[leftIndex] > carriedColumn:
      columns[leftIndex + 1] = columns[leftIndex]
      leftIndex -= 1
    columns[leftIndex + 1] = carriedColumn

let blockCount = nextInt(inputData, scanPos)
for blockIndex in 0 .. blockCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var initialColumns = newSeq[string](columnCount)
  var finalColumns = newSeq[string](columnCount)
  for columnIndex in 0 .. columnCount - 1:
    initialColumns[columnIndex] = ""
    finalColumns[columnIndex] = ""
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let pebbleColor = nextColor(inputData, scanPos)
      if pebbleColor == 'B':
        initialColumns[columnIndex].add '1'
      else:
        initialColumns[columnIndex].add '0'
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let pebbleColor = nextColor(inputData, scanPos)
      if pebbleColor == 'B':
        finalColumns[columnIndex].add '1'
      else:
        finalColumns[columnIndex].add '0'
  for columnIndex in 0 .. columnCount - 1:
    initialColumns[columnIndex] = canonicalColumn(initialColumns[columnIndex])
    finalColumns[columnIndex] = canonicalColumn(finalColumns[columnIndex])
  sortColumns(initialColumns)
  sortColumns(finalColumns)
  var transformable = true
  for columnIndex in 0 .. columnCount - 1:
    if initialColumns[columnIndex] != finalColumns[columnIndex]:
      transformable = false
      break
  if transformable:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")
stdout.write outputBuffer
outputBuffer.setLen 0
