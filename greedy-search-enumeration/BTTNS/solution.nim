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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let reach = nextInt(inputData, scanPos)
  let buttonCount = rowCount * columnCount
  let wordCount = (buttonCount + 64) div 64
  let resultWord = buttonCount div 64
  let resultMask = 1'u64 shl (buttonCount mod 64)
  var equations = newSeq[seq[uint64]](buttonCount)
  for cellRow in 0 .. rowCount - 1:
    for cellColumn in 0 .. columnCount - 1:
      var equationRow = newSeq[uint64](wordCount)
      for buttonRow in 0 .. rowCount - 1:
        for buttonColumn in 0 .. columnCount - 1:
          let buttonDistance = abs(cellRow - buttonRow) + abs(cellColumn - buttonColumn)
          if buttonDistance <= reach:
            let variableIndex = buttonRow * columnCount + buttonColumn
            let variableWord = variableIndex div 64
            equationRow[variableWord] = equationRow[variableWord] or (1'u64 shl (variableIndex mod 64))
      let cellValue = nextInt(inputData, scanPos)
      if cellValue == 1:
        equationRow[resultWord] = equationRow[resultWord] or resultMask
      equations[cellRow * columnCount + cellColumn] = equationRow
  var pivotRow = 0
  for pivotColumn in 0 .. buttonCount - 1:
    let pivotWord = pivotColumn div 64
    let pivotMask = 1'u64 shl (pivotColumn mod 64)
    var selectedRow = -1
    for equationIndex in pivotRow .. buttonCount - 1:
      if (equations[equationIndex][pivotWord] and pivotMask) != 0'u64:
        selectedRow = equationIndex
        break
    if selectedRow < 0:
      continue
    swap equations[pivotRow], equations[selectedRow]
    for equationIndex in 0 .. buttonCount - 1:
      if equationIndex != pivotRow and (equations[equationIndex][pivotWord] and pivotMask) != 0'u64:
        for currentWord in 0 .. wordCount - 1:
          equations[equationIndex][currentWord] = equations[equationIndex][currentWord] xor equations[pivotRow][currentWord]
    pivotRow += 1
  var pressedCount = 0
  for solutionIndex in 0 .. buttonCount - 1:
    if (equations[solutionIndex][resultWord] and resultMask) != 0'u64:
      pressedCount += 1
  appendOutput($pressedCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
