const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const clockwiseRows = [0, 1, 0, -1, 0]
const clockwiseCols = [1, 0, -1, 0, 1]
const counterRows = [1, 0, -1, 0, 1]
const counterCols = [0, 1, 0, -1, 0]

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc buildPattern(size: int): seq[string] =
  var rows = newSeq[string](size)
  for rowIndex in 0 ..< size:
    var line = ""
    for columnIndex in 0 ..< size:
      line.add '.'
    rows[rowIndex] = line
  var currentRow = 0
  var currentCol = 0
  rows[currentRow][currentCol] = '*'
  var group = 0
  while true:
    let groupSize = size - 1 - 4 * group
    if groupSize <= 0:
      break
    var rowSteps = clockwiseRows
    var colSteps = clockwiseCols
    if group mod 2 == 1:
      rowSteps = counterRows
      colSteps = counterCols
    var armLengths = [groupSize, groupSize, groupSize, groupSize - 2, 2]
    for armIndex in 0 .. 4:
      if armIndex == 2 and groupSize < 2:
        break
      if armIndex == 3 and groupSize < 3:
        break
      if armIndex == 4 and groupSize < 4:
        break
      var stepIndex = 0
      while stepIndex < armLengths[armIndex]:
        let nextRow = currentRow + rowSteps[armIndex]
        let nextCol = currentCol + colSteps[armIndex]
        if nextRow < 0 or nextRow >= size or nextCol < 0 or nextCol >= size:
          break
        currentRow = nextRow
        currentCol = nextCol
        rows[currentRow][currentCol] = '*'
        stepIndex += 1
    group += 1
  return rows

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let size = nextInt(inputData, scanPos)
  let rows = buildPattern(size)
  for rowIndex in 0 ..< size:
    appendOutput(rows[rowIndex])
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
